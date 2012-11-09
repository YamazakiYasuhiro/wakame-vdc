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
declare release_dir=${opsroot_dir}/`date +%Y%m%d%H%M%S`git01234567
declare release_tarball=${opsroot_dir}/${release_id}.tar.gz

## functions

function setUp() {
  function spot_build()  { echo spot_build  $*; }
}

##

function test_build_repo() {
  build_repo ${opsroot_dir} ${release_id}
  assertEquals "$?" "0"
}

function test_build_repo_branch_master() {
  build_repo ${opsroot_dir} ${release_id} master
  assertEquals "$?" "0"
}

##

function test_build_repo_no_args() {
  build_repo
  assertNotEquals "$?" "0"
}

function test_build_repo_opsroot_dir() {
  build_repo ${opsroot_dir}
  assertNotEquals "$?" "0"
}

## shunit2

. ${shunit2_file}
