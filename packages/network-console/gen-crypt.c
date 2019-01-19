#define _XOPEN_SOURCE
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>

static int i64c (int i)
{
  if (i <= 0)
    return ('.');
  if (i == 1)
    return ('/');
  if (i >= 2 && i < 12)
    return ('0' - 2 + i);
  if (i >= 12 && i < 38)
    return ('A' - 12 + i);
  if (i >= 38 && i < 63)
    return ('a' - 38 + i);
  return ('z');
}

int main (int argc, char *argv[])
{
  if (argc > 1)
  {
    char salt[12] = { '$', '1', '$', 0 };
    const char *crypted;
    int fd = open ("/dev/urandom", O_RDONLY);
    int i;
    ssize_t r;
    r = read (fd, salt + 3, 8);
    if (r < 0) {
      perror ("read /dev/urandom");
      return EXIT_FAILURE;
    } else if (r != 8) {
      /* Slightly lazy since technically we could read fewer bytes; but in
       * practice we should always be able to read 8 bytes from /dev/urandom
       * in one go without blocking.
       */
      fprintf (stderr,
               "Could only read %zd bytes from /dev/urandom, not 8\n", r);
      return EXIT_FAILURE;
    }
    for (i = 0; i < 8; i++)
      salt[3 + i] = i64c (salt[3 + i] % 64);
    crypted = crypt (argv[1], salt);
    puts (crypted);
    return EXIT_SUCCESS;
  }
  return EXIT_FAILURE;
}
