#!/bin/bash
#
# requires:
#   bash
#

## include files

. ./helper_shunit2.sh

## variables

declare opsroot_dir=opsroot_dir.$$

## functions

function setUp() {
  mkdir -p ${opsroot_dir}
  ln -s /bin/true ${opsroot_dir}/spot-build.sh
}

function tearDown() {
  rm    ${opsroot_dir}/spot-build.sh
  rmdir ${opsroot_dir}
}

##

function test_spot_build() {
  spot_build ${opsroot_dir}
  assertEquals "$?" "0"
}

## shunit2

. ${shunit2_file}
