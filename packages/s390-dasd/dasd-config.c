#include <ctype.h>
#include <errno.h>
#include <fcntl.h>
#include <limits.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/ioctl.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>

#include <cdebconf/debconfclient.h>
#include <debian-installer.h>

#include <libsysfs.h>

#define SYSCONFIG_DIR "/etc/sysconfig/hardware/"
#define TEMPLATE_PREFIX	"s390-dasd/"
#define DASD_ENTRY_SIZE	32

static struct debconfclient *client;

enum channel_type
{
	CHANNEL_TYPE_DASD_ECKD,
	CHANNEL_TYPE_DASD_FBA
};

struct channel
{
	int key;
	char name[SYSFS_NAME_LEN];
	char devtype[SYSFS_NAME_LEN];
	bool configured;
	bool online;
	bool formatted;
	enum channel_type type;
};

static di_tree *channels;

static struct channel *channel_current;

struct driver
{
	const char *name;
	int type;
};

static const struct driver drivers[] =
{
	{ "dasd-eckd", CHANNEL_TYPE_DASD_ECKD },
	{ "dasd-fba", CHANNEL_TYPE_DASD_FBA },
};

enum state
{
	BACKUP,
	SETUP,
	DETECT_CHANNELS,
	GET_CHANNEL,
	ENABLE,
	FORMAT,
	WRITE,
	ERROR,
	FINISH
};

enum state_wanted
{
	WANT_NONE = 0,
	WANT_BACKUP,
	WANT_NEXT,
	WANT_FINISH,
	WANT_ERROR
};

int my_debconf_input(char *priority, char *template, char **ptr)
{
	int ret;
	debconf_input (client, priority, template);
	ret = debconf_go (client);
	debconf_get (client, template);
	*ptr = client->value;
	return ret;
}

static di_compare_func channel_compare;
int channel_compare (const void *key1, const void *key2)
{
	const unsigned int *k1 = key1, *k2 = key2;
	return *k1 - *k2;
}

static int channel_device (const char *i)
{
	unsigned int ret;
	if (sscanf (i, "0.0.%04x", &ret) == 1)
		return ret;
	if (sscanf (i, "%04x", &ret) == 1)
		return ret;
	return -1;
}

static enum state_wanted setup ()
{
	channels = di_tree_new (channel_compare);

	return WANT_NEXT;
}

static enum state_wanted detect_channels_driver (struct sysfs_driver *driver, int type)
{
	char path[PATH_MAX];
	struct dlist *devices;
	struct sysfs_device *device;

	devices = sysfs_get_driver_devices (driver);
	if (!devices)
		return WANT_NONE;

	dlist_for_each_data (devices, device, struct sysfs_device)
	{
		struct sysfs_attribute *attr_devtype, *attr_online;
		struct channel *current;

		attr_devtype = sysfs_get_device_attr (device, "devtype");
		attr_online = sysfs_get_device_attr (device, "online");
		if (!attr_devtype || !attr_online)
			return WANT_NONE;
		current = di_new0 (struct channel, 1);
		if (!current)
			return WANT_ERROR;
		strncpy (current->name, device->name, sizeof (current->name));
		current->key = channel_device(device->name);

		sysfs_read_attribute (attr_devtype);
		strncpy (current->devtype, attr_devtype->value, sizeof (current->devtype));
		current->type = type;

		sysfs_read_attribute (attr_online);
		if (strtol (attr_online->value, NULL, 10) > 0)
			current->online = true;

		/* Check if the current DASD is already configured */
		snprintf (path, sizeof (path), SYSCONFIG_DIR "config-ccw-%s", current->name);
		current->configured = access (path, F_OK) == 0;

		di_tree_insert (channels, current, current);
	}

	return WANT_NONE;
}

static enum state_wanted detect_channels (void)
{
	struct sysfs_driver *driver;
	enum state_wanted ret;
	unsigned int i;

	for (i = 0; i < sizeof (drivers) / sizeof (*drivers); i++)
	{
		driver = sysfs_open_driver ("ccw", drivers[i].name);
		if (driver)
		{
			ret = detect_channels_driver (driver, drivers[i].type);
			sysfs_close_driver (driver);
			if (ret)
				return ret;
		}
	}
	return WANT_NEXT;
}

struct buffer_desc
{
	char	*buf;
	size_t	size;
};

static di_hfunc get_channel_select_append;
static void get_channel_select_append (void *key __attribute__ ((unused)), void *value, void *user_data)
{
	struct channel *channel = value;
	struct buffer_desc *bd = user_data;

	if (bd->buf[0])
		di_snprintfcat (bd->buf, bd->size, ", ");
	di_snprintfcat(bd->buf, bd->size, channel->name);
	if (channel->configured)
		di_snprintfcat (bd->buf, bd->size, " (configured)");
	else if (channel->online)
		di_snprintfcat (bd->buf, bd->size, " (online)");
}

static enum state_wanted get_channel_select (void)
{
	struct buffer_desc bd;
	int ret, dev;
	char *ptr;

	/*
	 * Allocate memory to store DASD bus-IDs along with their
	 * online or configured state information.
	 */
	bd.size = DASD_ENTRY_SIZE * di_tree_size (channels);
	bd.buf = di_malloc0 (bd.size);
	if (bd.buf == NULL)
	{
		di_warning ("Could not allocate memory for DASD list\n");
		return WANT_ERROR;
	}
	di_tree_foreach (channels, get_channel_select_append, &bd);

	debconf_subst (client, TEMPLATE_PREFIX "choose_select", "choices", bd.buf);
	ret = my_debconf_input ("critical", TEMPLATE_PREFIX "choose_select", &ptr);

	if (ret == 30)
	{
		di_free (bd.buf);
		return WANT_BACKUP;
	}
	if (!strcmp (ptr, "Finish"))
	{
		di_free (bd.buf);
		return WANT_FINISH;
	}

	dev = channel_device (ptr);
	di_free (bd.buf);
	channel_current = di_tree_lookup (channels, &dev);
	if (channel_current)
		return WANT_NEXT;
	di_error("s390-dasd: could not get selected channel device %d", dev);
	return WANT_ERROR;
}

static enum state_wanted get_channel (void)
{
	if (di_tree_size (channels) > 0)
		return get_channel_select ();
	di_info("s390-dasd: no channel found");
	return WANT_FINISH;
}

static enum state_wanted enable (void)
{
	struct sysfs_device *device;
	struct sysfs_attribute *attr;

	if (channel_current->online)
		return WANT_NEXT;

	device = sysfs_open_device ("ccw", channel_current->name);
	if (!device) {
		di_error("s390-dasd: could not open device %s",
			channel_current->name);
		return WANT_ERROR;
	}

	attr = sysfs_get_device_attr (device, "online");
	if (!attr) {
		di_error("s390-dasd: could not read online attribute for %s",
			channel_current->name);
		return WANT_ERROR;
	}
	if (sysfs_write_attribute (attr, "1", 1) < 0) {
		di_error("s390-dasd: could not set %s online: %s",
			channel_current->name, strerror(errno));
		return WANT_ERROR;
	}

	sysfs_close_device (device);

	channel_current->online = true;

	return WANT_NEXT;
}

struct hd_geometry {
	unsigned char heads;
	unsigned char sectors;
	unsigned short cylinders;
	unsigned long start;
};

#define HDIO_GETGEO 0x0301  

static di_io_handler format_handler;

static int format_handler (const char *buf, size_t len, void *user_data __attribute__ ((unused)))
{
	if (len == 1 && buf[0] == '#')
		debconf_progress_step (client, 1);
	else
		di_log (DI_LOG_LEVEL_OUTPUT, "%s", buf);
	return 0;
}

static bool dasd_is_formatted (const char *name)
{
	int tries;
	bool formatted;
	struct sysfs_device *device;
	struct sysfs_attribute *status;

	formatted = false;
	device = sysfs_open_device ("ccw", name);
	if (!device)
	{
		di_warning ("s390-dasd: could not open device %s", name);
		return false;
	}

	/* Examine the status of the DASD to retrieve information whether
	 * the DASD is already low-level formatted.
	 */
	status = sysfs_get_device_attr (device, "status");
	if (!status)
	{
		di_warning ("s390-dasd: could not find status attribute for %s", name);
		sysfs_close_device (device);
		return false;
	}

	tries = 5;
	while (tries--)
	{
		sysfs_read_attribute (status);

		/* DASD is low-level formatted and in the online state? */
		if (!strcmp (status->value, "online\n"))
		{
			formatted = true;
			break;
		}

		/* DASD is not low-level formatted? */
		if (!strcmp (status->value, "unformatted\n"))
			break;

		/* Give the DASD device driver some time to complete
		 * DASD online processing.
		 */
		usleep (250000);
	}

	sysfs_close_device (device);
	return formatted;
}

static enum state_wanted format (void)
{
	char buf[256], dev[128], *ptr, *template;
	int fd, ret;
	struct hd_geometry drive_geo;

	/* Retrieve information about the format status of the DASD */
	channel_current->formatted = dasd_is_formatted (channel_current->name);
	template = channel_current->formatted ? TEMPLATE_PREFIX "format"
					      : TEMPLATE_PREFIX "format_required";
	/*
	 * Depending on whether the DASD is already formatted,
	 * use the respective template, its default, and priority.
	 */
	debconf_reset (client, template);
	debconf_subst (client, template, "device", channel_current->name);
	ret = my_debconf_input (channel_current->formatted ? "high" : "critical",
				template, &ptr);

	if (ret == CMD_GOBACK)
		return WANT_BACKUP;
	/* Prohibit to configure a DASD that is not formatted */
	if (strcmp (ptr, "true") && !channel_current->formatted)
		return WANT_BACKUP;
	if (strcmp (ptr, "true"))
		return WANT_NEXT;

	snprintf (dev, sizeof (dev), "/dev/disk/by-path/ccw-%s", channel_current->name);

	fd = open (dev, O_RDONLY);
	if (fd < 0)
		return WANT_ERROR;
	if (ioctl (fd, HDIO_GETGEO, &drive_geo) < 0)
		return WANT_ERROR;
	close (fd);

	debconf_subst (client, TEMPLATE_PREFIX "formatting", "device", channel_current->name);
	debconf_progress_start (client, 0, drive_geo.cylinders - 1, TEMPLATE_PREFIX "formatting");

	snprintf (buf, sizeof (buf), "dasdfmt -l LX%04x -b 4096 -m 1 -f %s -y", channel_device (channel_current->name), dev);
	ret = di_exec_shell_full (buf, format_handler, NULL, NULL, NULL, NULL, NULL, NULL);

	debconf_progress_stop (client);

	if (ret)
	{
		if (di_exec_mangle_status (ret) == 2)
		{
			/*
			 * dasdfmt failed because the DASD is in use. For example,
			 * it is mapped as part of an LVM.
			 */
			debconf_subst (client, TEMPLATE_PREFIX "format_disk_in_use",
				       "device", channel_current->name);
			debconf_input (client, "critical",
				       TEMPLATE_PREFIX "format_disk_in_use");
			debconf_capb (client);
			ret = debconf_go (client);
			debconf_capb (client, "backup");

			return WANT_BACKUP;
		}
		return WANT_ERROR;
	} else {
		/* DASD successfully low-level formatted */
		channel_current->formatted = true;
	}

	return WANT_NEXT;
}

static enum state_wanted write_dasd (void)
{
        char buf[256];
        FILE *config;

        snprintf (buf, sizeof (buf), SYSCONFIG_DIR "config-ccw-%s", channel_current->name);
        config = fopen (buf, "w");
        if (!config)
                return WANT_ERROR;

        fclose (config);

	channel_current->configured = true;

	return WANT_NEXT;
}

int main ()
{
	di_system_init ("s390-dasd");

	client = debconfclient_new ();
	debconf_capb (client, "backup");

	enum state state = SETUP;

	while (1)
	{
		enum state_wanted state_want = WANT_ERROR;

		switch (state)
		{
			case BACKUP:
				return 10;
			case SETUP:
				state_want = setup ();
				break;
			case DETECT_CHANNELS:
				state_want = detect_channels ();
				break;
			case GET_CHANNEL:
				state_want = get_channel ();
				break;
			case ENABLE:
				state_want = enable ();
				break;
			case FORMAT:
				state_want = format ();
				break;
			case WRITE:
				state_want = write_dasd ();
				break;
			case ERROR:
				return 1;
			case FINISH:
				return 0;
		}
		switch (state_want)
		{
			case WANT_NEXT:
				switch (state)
				{
					case SETUP:
						state = DETECT_CHANNELS;
						break;
					case DETECT_CHANNELS:
						state = GET_CHANNEL;
						break;
					case GET_CHANNEL:
						state = ENABLE;
						break;
					case ENABLE:
						if (channel_current->type == CHANNEL_TYPE_DASD_ECKD)
							state = FORMAT;
						else
							state = WRITE;
						break;
					case FORMAT:
						state = WRITE;
						break;
					case WRITE:
						state = GET_CHANNEL;
						break;
					default:
						state = ERROR;
				}
				break;
			case WANT_BACKUP:
				switch (state)
				{
					case GET_CHANNEL:
						state = BACKUP;
						break;
					case FORMAT:
					case WRITE:
						state = GET_CHANNEL;
						break;
					default:
						state = ERROR;
				}
				break;
			case WANT_FINISH:
				state = FINISH;
				break;
			default:
				state = ERROR;
		}
	}
}

/* vim: noexpandtab sw=8
*/
