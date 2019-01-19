#include <sys/types.h>
#include <regex.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#include <debian-installer/system/subarch.h>

struct hwmap_type {
	const char *sys_regex;
	const char *cpu_regex;
	const char *isa_regex;
	const char *ret;
};

static struct hwmap_type hwmap[] = {
	{"MIPS Malta",		"MIPS (4K|24K|34K|74K)",	".*",		"4kc-malta" },
	{"MIPS Malta",		"MIPS (5K|20K)",		".*",		"5kc-malta" },
	{"MIPS Malta",		".*",				"mips64r2",	"5kc-malta" },
	{"MIPS Malta",		".*",				"mips32r2",	"4kc-malta" },
	{".*",			"ICT Loongson-3",		".*",		"loongson-3" },
	{".*",			"Cavium Octeon",		".*",		"octeon" },

	/* add new hwmap here */

	{ ".*",			".*",				".*", 	"unknown" }
};

#define BUFFER_LENGTH (1024)

const char *di_system_subarch_analyze(void)
{
	FILE *file;
	char buf[BUFFER_LENGTH];
	const char *pos;
	char *system = NULL, *cpu = NULL, *isa = NULL;
	size_t len, i;

	file = fopen("/proc/cpuinfo", "r");

	if (file) {
		while (fgets(buf, sizeof(buf), file)) {
			if (!(pos = strchr(buf, ':')))
				continue;
			if (!(len = strspn(pos, ": \t")))
				continue;
			if (!strncmp(buf, "system type", strlen("system type")))
				system = strdup(pos + len);
			if (!strncmp(buf, "cpu model", strlen("cpu model")))
				cpu = strdup(pos + len);
			if (!strncmp(buf, "isa", strlen("isa")))
				isa = strdup(pos + len);
		}

		fclose(file);
	}

	if (!system)
		system = strdup("");
	if (!cpu)
		cpu = strdup("");
	if (!isa)
		cpu = strdup("");

	for (i = 0; i < sizeof(hwmap) / sizeof(struct hwmap_type) ; i++) {
		regex_t preg;
		int ret;

		/* Check for matching system type */
		if (regcomp(&preg, hwmap[i].sys_regex, REG_NOSUB | REG_EXTENDED))
			continue;
		ret = regexec(&preg, system, 0, NULL, 0);
		regfree(&preg);
		if (ret == REG_NOMATCH)
			continue;

		/* Check for matching cpu type */
		if (regcomp(&preg, hwmap[i].cpu_regex, REG_NOSUB | REG_EXTENDED))
			continue;
		ret = regexec(&preg, cpu, 0, NULL, 0);
		regfree(&preg);
		if (ret == REG_NOMATCH)
			continue;

		/* Check for matching isa type */
		if (regcomp(&preg, hwmap[i].isa_regex, REG_NOSUB | REG_EXTENDED))
			continue;
		ret = regexec(&preg, isa, 0, NULL, 0);
		regfree(&preg);
		if (ret == REG_NOMATCH)
			continue;

		/* Match system, cpu and isa type. Stop. */
		break;
	}

	free(system);
	free(cpu);

	return hwmap[i].ret;
}
