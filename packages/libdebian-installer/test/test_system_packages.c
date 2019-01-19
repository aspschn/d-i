#include <stdio.h>
#include <string.h>
#include <ctype.h>

#include <check.h>

#include <debian-installer/package.h>
#include <debian-installer/string.h>
#include <debian-installer/system/packages.h>

#include "test_system_packages.h"

#define DOWNLOAD_PACKAGES       DATADIR "/Packages"

static di_packages *packages = NULL;
static di_packages_allocator *packages_allocator = NULL;

START_TEST(test_size)
{
    di_slist_node *node;
    int count;

    count = 0;
    for (node = (packages)->list.head; node; node = node->next) {
      count++;
    }

    ck_assert_int_eq(di_hash_table_size(packages->table), count);
}
END_TEST

START_TEST(test_dependencies)
{
    di_slist_node *node;
    di_package *package;

    /* verify packages initial status_want */
    for (node = (packages)->list.head; node; node = node->next) {
      package = node->data;
      ck_assert_int_eq(package->status_want, di_package_status_want_unknown);
    }

    /* we want to install countrychooser */
    node = (packages)->list.head;
    package = node->data;
    package->status_want = di_package_status_want_install;

    /* check dependencies */
    di_system_packages_resolve_dependencies_mark_anna(packages,NULL,NULL);

    /* verify packages status_want is status_want_install*/
    for (node = (packages)->list.head; node; node = node->next) {
      package = node->data;
      ck_assert_int_eq(package->status_want, di_package_status_want_install);
    }
}
END_TEST

static void setup() {
  packages_allocator = di_system_packages_allocator_alloc();
  packages = di_system_packages_read_file(DOWNLOAD_PACKAGES, packages_allocator);
}

static void teardown() {
  di_packages_free(packages);
  di_packages_allocator_free(packages_allocator);
  packages = NULL;
  packages_allocator = NULL;
}

Suite* make_test_system_packages_suite() {
  Suite *s;
  TCase *tc_core;

  s = suite_create("test system packages");
  tc_core = tcase_create("Core");
  tcase_add_checked_fixture(tc_core, setup, teardown);
  tcase_add_test(tc_core, test_size);
  tcase_add_test(tc_core, test_dependencies);
  suite_add_tcase(s, tc_core);

  return s;
}
