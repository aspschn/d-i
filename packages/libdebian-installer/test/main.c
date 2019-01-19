#include <stdlib.h>

#include <check.h>

#include "test_exec.h"
#include "test_hash.h"
#include "test_system_packages.h"

int main() {
  int number_failed;
  SRunner *sr;

  sr = srunner_create(make_test_hash_suite());
  srunner_add_suite(sr, make_test_system_packages_suite());
  srunner_add_suite(sr, make_test_exec_suite());
  srunner_run_all(sr, CK_NORMAL);
  number_failed = srunner_ntests_failed(sr);
  srunner_free(sr);

  return (number_failed == 0) ? EXIT_SUCCESS : EXIT_FAILURE;
}
