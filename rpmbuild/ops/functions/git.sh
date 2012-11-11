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
