#include <debian-installer/system/subarch.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#define BUFFER_LENGTH (1024)

typedef struct {
  const char *cpuinfo_type;
  const char *sun_subarch;
  const char *gpt_subarch;
} subarch_map_t;

static const char *subarch_string(const char *cpuinfo_type, int is_gpt)
{
  static const subarch_map_t subarch_map[] = {
    { "sun4m", "sun4m_sun", "sun4m_gpt" },
    { "sun4u", "sun4u_sun", "sun4u_gpt" },
    { "sun4v", "sun4v_sun", "sun4v_gpt" },
  };
  size_t i;
  for (i = 0; i < sizeof(subarch_map)/sizeof(subarch_map[0]); i++)
  {
    if (!strncasecmp(subarch_map[i].cpuinfo_type, cpuinfo_type, strlen(subarch_map[i].cpuinfo_type)))
    {
      if (is_gpt)
        return subarch_map[i].gpt_subarch;
      else
        return subarch_map[i].sun_subarch;
    }
  }
  return NULL;
}

const char *di_system_subarch_analyze(void) 
{
  FILE *file;
  char buf[BUFFER_LENGTH];
  const char *pos;
  const char *subarch = NULL;
  size_t len;
  int is_gpt;

  is_gpt = access("/sys/firmware/devicetree/base/packages/disk-label/gpt", F_OK) != -1;

  file = fopen("/proc/cpuinfo", "r");

  if (file) {
    while (fgets(buf, sizeof(buf), file)) {
      if (!(pos = strchr(buf, ':')))
	continue;
      if (!(len = strspn(pos, ": \t")))
	continue;
      if (!strncmp(buf, "type", strlen("type")))
	subarch = subarch_string(pos + len, is_gpt);
    }

    fclose(file);
  }

  return subarch;
}
