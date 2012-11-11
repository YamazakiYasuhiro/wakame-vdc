#!/bin/bash
#
# requires:
#  bash
#  git, sed
#
# imports:
#

function current_branch_name() {
  git branch --no-color | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/'
}

function short_hash() {
  local build_id=${1:-HEAD}
  git log ${build_id} -n 1 --pretty=format:"%h"
}
