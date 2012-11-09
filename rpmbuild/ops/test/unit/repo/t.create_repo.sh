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

  function check_repo_dir() { echo check_repo_dir $*; }
  function build_repo()     { echo build_repo     $*; }
  function upload_repo()    { echo upload_repo    $*; }
}

function tearDown() {
  [[ -f "${release_tarball}" ]] && rm    ${release_tarball} || :
  [[ -d "${release_dir}"     ]] && rmdir ${release_dir}     || :
  [[ -d "${opsroot_dir}"     ]] && rmdir ${opsroot_dir}     || :
}

##

function test_create_repo() {
  create_repo ${opsroot_dir}
  assertEquals "$?" "0"
}

## shunit2

. ${shunit2_file}
