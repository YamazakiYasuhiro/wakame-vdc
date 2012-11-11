#!/bin/bash
#
# requires:
#  bash
#  git, sed
#  date
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

function commit_cd() {
  local short_hash=${1:-HEAD}
  date --date="$(git log ${git_version} -n 1 --pretty=format:"%cd" --date=iso)" +%Y%m%d%H%M%S
}

function release_id() {
  local build_id=${1:-HEAD}

  local short_hash=$(short_hash ${build_id})
  local commit_cd=$(commit_cd ${git_version})

  echo ${commit_cd}git${short_hash}
}
