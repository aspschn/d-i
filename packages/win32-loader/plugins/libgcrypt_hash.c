/* libgcrypt-hash.c
 * Copyright (C) 2016, Didier Raboud
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
 * You should have received a copy of the GNU General Public License along
 * with this program; if not, write to the Free Software Foundation, Inc.,
 * 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
 */

#include <gcrypt.h>
#include <stdio.h>
#include <errno.h>

/* NSIS plugin
*/
#include <windows.h>
#ifdef HAVE_EXDLL_H
#include "exdll.h"
#else
#include <nsis/pluginapi.h>
#endif

BOOL WINAPI DllMain (HANDLE hInst, ULONG ul_reason_for_call, LPVOID lpReserved)
{
  return TRUE;
}

void hash_fp(char **outhash, int hash_algo, char *filename[]) {
    /* Length of resulting hash - gcry_md_get_algo_dlen
     * returns digest lenght for an algo */
    int hash_len = gcry_md_get_algo_dlen( hash_algo );

    /* output hash - this will be binary data */
    unsigned char hash[ hash_len ];

    /* output hash - converted to hex representation
     * 2 hex digits for every byte + 1 for trailing \0 */
    *outhash = NULL;
    *outhash = (char *) malloc( sizeof(char) * ((hash_len*2)+1) );
    char *p = *outhash;

    /* File-reading */
    FILE *fp;
    char buffer[4096];
    size_t n;
    gcry_md_hd_t hd;
    unsigned char *hash_ptr;

    /* Initialize hash */
    gcry_md_open (&hd, hash_algo, 0);

    fp = fopen (*filename, "rb");
    if (!fp)
    {
	fprintf (stderr, "can't open `%s': %s\n", *filename, strerror (errno));
	exit (1);
    }
    while ( (n = fread (buffer, 1, sizeof buffer, fp)))
	gcry_md_write(hd, buffer, n);
    if (ferror (fp))
    {
	fprintf (stderr, "error reading `%s': %s\n", *filename,strerror (errno));
	exit (1);
    }
    gcry_md_final(hd);
    fclose (fp);
    hash_ptr = gcry_md_read (hd, hash_algo);
    if (hash_ptr == NULL)
    {
	fprintf (stderr, "gcry_md_read failed.");
	gcry_md_close (hd);
	exit (1);
    }
    memcpy (hash, hash_ptr, sizeof (hash));

    /* Convert each byte to its 2 digit ascii
     * hex representation and place in outhash */
    int i;
    for ( i = 0; i < hash_len; i++, p += 2 ) {
	snprintf ( p, 3, "%02x", hash[i] );
    }
}

void __declspec (dllexport) hashsum (HWND hwndParent, int string_size, char *variables, stack_t ** stacktop, extra_parameters * extra)
{
  EXDLL_INIT ();

  // First argument is the hash name (md5, sha1, sha256, etc)
  char hashname[8];
  char *h = hashname;
  popstring (hashname);

  char filename[1024];
  char *f = filename;
  popstring (filename);

  char *hashhex;
  if (strcmp(hashname, "sha1") == 0) {
        hash_fp(&hashhex, GCRY_MD_SHA1, &f);
  } else if (strcmp(hashname, "sha256") == 0) {
        hash_fp(&hashhex, GCRY_MD_SHA256, &f);
  } else if (strcmp(hashname, "sha512") == 0) {
        hash_fp(&hashhex, GCRY_MD_SHA512, &f);
  } else {
      pushstring("false");
  }

  pushstring(hashhex);
  free(hashhex);
}
