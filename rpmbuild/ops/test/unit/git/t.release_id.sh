#!/bin/bash
#
# requires:
#   bash
#

## include files

. ./helper_shunit2.sh

## variables

## functions

function test_release_id() {
  release_id
  assertEquals "$?" "0"
}

## shunit2

. ${shunit2_file}
