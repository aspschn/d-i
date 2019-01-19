/*
 * efi.c
 *
 * Copyright (C) 2012 Steve McIntyre <steve@einval.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301, USA.
 */

#include <unistd.h>

#include <debian-installer/system/efi.h>

/* Are we on an EFI system? Check to see if /sys/firmware/efi
 * exists */
int di_system_is_efi(void)
{
	int efivars_access = access("/sys/firmware/efi/efivars", R_OK);
	int vars_access = access("/sys/firmware/efi/vars", R_OK);
	if (efivars_access == 0 || vars_access == 0)
	{
		/* Have we been told to ignore EFI in partman-efi? */
		int ret = access("/var/lib/partman/ignore_uefi", R_OK);
		if (ret == 0)
			return 0;
		else
			return 1;
	}
	else
		return 0;
}

