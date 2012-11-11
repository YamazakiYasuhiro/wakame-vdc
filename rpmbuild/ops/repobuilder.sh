#!/bin/bash
#
# requires:
#  bash
#  gen-release-id.sh
#
set -e

## private functions

### read-only variables

readonly abs_dirname=$(cd $(dirname $0) && pwd)

### variables

declare release_id=$(${abs_dirname}/../helpers/gen-release-id.sh)

## include files

. ${abs_dirname}/functions/utils.sh
. ${abs_dirname}/functions/git.sh
. ${abs_dirname}/functions/repo.sh

### prepare

extract_args $*

## main

create_repo ${abs_dirname}
