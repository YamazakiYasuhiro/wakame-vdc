#!/bin/bash
#
# requires:
#   bash
#

## include files

. ./helper_shunit2.sh

## variables

## functions

function test_current_branch_name() {
  current_branch_name
  assertEquals "$?" "0"
}

## shunit2

. ${shunit2_file}
