#!/bin/bash
#
# requires:
#   bash
#   rsync, tar, ls
#
set -e
set -x

abs_dirname=$(cd $(dirname $0) && pwd)

[[ $UID -ne 0 ]] && {
  echo "ERROR: Run as root" >/dev/stderr
  exit 1
}

cd ${abs_dirname}

release_id=$(../helpers/gen-release-id.sh)
[[ -f ${release_id}.tar.gz ]] && {
  echo "already built: ${release_id}" >/dev/stderr
  exit 0
} || :

# exec 2>${release_id}.err
#
# Jenkins reported following errors.
#
# + exec
# Build step 'Execute shell' marked build as failure
# Finished: FAILURE

time REPO_URI=$(cd ../../.git && pwd) ./rules clean rpm

[[ -d pool ]] && rm -rf pool || :
time ./createrepo-vdc.sh

[[ -d ${release_id} ]] && rm -rf ${release_id} || :
rsync -avx pool/vdc/current/ ${release_id}

tar zcvpf ${release_id}.tar.gz ${release_id}
ls -la ${release_id}.tar.gz
