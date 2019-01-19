/*
 * Licensed under GPLv2
 *
 * Print out major:minor number of the real console device,
 * using the TIOCGDEV ioctl (only works on kernels >= 2.6.38).
 * 
 * Copyright (c) 2011 Jurij Smakov <jurij@debian.org>
 */

#include <stdio.h>
#include <sys/ioctl.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <sys/sysmacros.h>

int main()
{
    int fd = 0;
    unsigned int dev;
       
    fd = open("/dev/console", O_WRONLY, 0);
    if (fd < 0) {
        perror("open");
        return(1);
    }
    if (ioctl(fd, TIOCGDEV, &dev) < 0) {
        perror("ioctl");
        return(2);
    }
    printf("%d:%d\n", major(dev), minor(dev));
    return(0);
}
