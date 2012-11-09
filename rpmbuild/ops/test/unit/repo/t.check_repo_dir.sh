#!/bin/bash
#
# requires:
#   bash
#

## include files

. ./helper_shunit2.sh

## variables

declare opsroot_dir=opsroot_dir.$$
declare release_id=`date +%Y%m%d%H%M%S`git01234567

## functions

function setUp() {
  mkdir -p ${opsroot_dir}
}

function tearDown() {
  [[ -d "${opsroot_dir}" ]] && rmdir ${opsroot_dir} || :
}

##

function test_check_repo_dir() {
  check_repo_dir ${opsroot_dir} ${release_id}
  assertEquals "$?" "0"
}

##

function test_check_repo_dir_no_args() {
  check_repo_dir
  assertNotEquals "$?" "0"
}

function test_check_repo_dir_no_release_id() {
  check_repo_dir ${opsroot_dir}
  assertNotEquals "$?" "0"
}

## shunit2

. ${shunit2_file}
