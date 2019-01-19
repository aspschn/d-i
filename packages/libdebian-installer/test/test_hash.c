#include <stdio.h>
#include <string.h>
#include <unistd.h>

#include <check.h>

#include <debian-installer/hash.h>
#include <debian-installer/string.h>

#include "test_hash.h"

#define STRING_MAX_LENGTH 10
#define KEY_VALUE_NBR 20

static void get_key(const char *name, di_rstring *key) {
  size_t size;

  size = strlen (name);

  /* i know that is bad, but i know it is not written by the lookup */
  key->string = (char *) name;
  key->size = size;
}

START_TEST(test_hash)
{
  di_hash_table *table;
  int i,nbr_of_insert=20;
  char str[KEY_VALUE_NBR][STRING_MAX_LENGTH];
  di_rstring key[KEY_VALUE_NBR];


  table = di_hash_table_new(di_rstring_hash, di_rstring_equal);

  for (i=0;i<nbr_of_insert;i++) {
    snprintf(str[i],STRING_MAX_LENGTH,"%d",i);
    get_key(str[i],&key[i]);
    di_hash_table_insert (table, &key[i], str[i]);
  }
  ck_assert_int_eq(di_hash_table_size(table), nbr_of_insert);
  di_hash_table_destroy(table);
}
END_TEST

Suite* make_test_hash_suite() {
  Suite *s;
  TCase *tc_core;

  s = suite_create("test hash table");
  tc_core = tcase_create("Core");
  tcase_add_test(tc_core, test_hash);
  suite_add_tcase(s, tc_core);

  return s;
}
