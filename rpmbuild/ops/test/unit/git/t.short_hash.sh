#!/bin/bash
#
# requires:
#   bash
#

## include files

. ./helper_shunit2.sh

## variables

## functions

function test_short_hash() {
  short_hash
  assertEquals "$?" "0"
}

## shunit2

. ${shunit2_file}
