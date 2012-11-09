#!/bin/bash
#
# requires:
#   bash
#

## include files

. ./helper_shunit2.sh

## functions

function test_add_repo_options() {
  add_repo_options
  assertEquals "$?" "0"
}

function test_add_repo_options_set_release_id() {
  declare release_id=asdf

  add_repo_options
  [[ -n "${release_id}" ]]

  assertEquals "$?" "0"
}

function test_add_repo_options_set_s3_backet() {
  declare s3_backet=asdf

  add_repo_options
  [[ -n "${s3_backet}" ]]

  assertEquals "$?" "0"
}

function test_add_repo_options_set_repo_base_path() {
  declare repo_base_path=packages/rhel/6

  add_repo_options
  [[ -n "${repo_base_path}" ]]

  assertEquals "$?" "0"
}

function test_add_repo_options_set_repo_base_uri() {
  declare repo_base_uri=s3://wakewakame/packages/rhel/6

  add_repo_options
  [[ -n "${repo_base_uri}" ]]

  assertEquals "$?" "0"
}


## shunit2

. ${shunit2_file}
