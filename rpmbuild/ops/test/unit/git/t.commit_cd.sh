#!/bin/bash
#
# requires:
#   bash
#

## include files

. ./helper_shunit2.sh

## variables

## functions

function test_commit_cd() {
  commit_cd
  assertEquals "$?" "0"
}

## shunit2

. ${shunit2_file}
