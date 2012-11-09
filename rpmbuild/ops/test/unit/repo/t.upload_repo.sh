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
  mkdir -p ${opsroot_dir}
  mkdir -p ${release_dir}
  touch    ${release_tarball}

  function s3cmd() { echo s3cmd $*; }
}

function tearDown() {
  [[ -f "${release_tarball}" ]] && rm    ${release_tarball} || :
  [[ -d "${release_dir}"     ]] && rmdir ${release_dir}     || :
  [[ -d "${opsroot_dir}"     ]] && rmdir ${opsroot_dir}     || :
}

##

function test_upload_repo() {
  upload_repo ${opsroot_dir} ${release_id}
  assertEquals "$?" "0"
}

function test_upload_repo_branch_master() {
  upload_repo ${opsroot_dir} ${release_id} master
  assertEquals "$?" "0"
}

##

function test_upload_repo_no_args() {
  upload_repo
  assertNotEquals "$?" "0"
}

function test_upload_repo_opsroot_dir() {
  upload_repo ${opsroot_dir}
  assertNotEquals "$?" "0"
}

## shunit2

. ${shunit2_file}
