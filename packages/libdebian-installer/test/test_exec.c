#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#include <check.h>

#include <debian-installer/types.h>
#include <debian-installer/exec.h>

#include "test_exec.h"

START_TEST(test_exec)
{
  const char* argv[] = {"/bin/echo", "test", NULL};
  int retval = di_exec(argv[0], argv);
  ck_assert_int_eq(di_exec_mangle_status(retval), 0);
}
END_TEST

START_TEST(test_exec_fail)
{
  const char* argv[] = {"/bin/false", NULL};
  int retval = di_exec(argv[0], argv);
  ck_assert_int_eq(di_exec_mangle_status(retval), 1);
}
END_TEST

START_TEST(test_exec_shell)
{
  int retval = di_exec_shell("/bin/echo test");
  ck_assert_int_eq(di_exec_mangle_status(retval), 0);
}
END_TEST

START_TEST(test_exec_shell_fail)
{
  int retval = di_exec_shell("/bin/false ignored arguments");
  ck_assert_int_eq(di_exec_mangle_status(retval), 1);
}
END_TEST

static void* outbuf = NULL;
static size_t outlen = 0;

static int stdout_handler(const char* buf, size_t len, __attribute__ ((unused)) void *user_data) {
  outbuf = realloc(outbuf, outlen + len);
  memcpy(outbuf + outlen, buf, len);
  outlen += len;
  return 0;
}

START_TEST(test_exec_stdout_capture)
{
  const char* expected_output = "test";
  int retval;
  retval = di_exec_shell_full("/bin/echo test", stdout_handler, NULL, NULL, NULL, NULL, NULL, NULL);
  ck_assert_int_eq(di_exec_mangle_status(retval), 0);
  ck_assert_int_eq(outlen, strlen(expected_output));
  ck_assert_int_eq(strncmp(expected_output, outbuf, outlen), 0);
}
END_TEST

Suite* make_test_exec_suite() {
  Suite *s;
  TCase *tc_core;

  s = suite_create("test exec");
  tc_core = tcase_create("Core");
  tcase_add_test(tc_core, test_exec);
  tcase_add_test(tc_core, test_exec_fail);
  tcase_add_test(tc_core, test_exec_shell);
  tcase_add_test(tc_core, test_exec_shell_fail);
  tcase_add_test(tc_core, test_exec_stdout_capture);
  suite_add_tcase(s, tc_core);

  return s;
}
