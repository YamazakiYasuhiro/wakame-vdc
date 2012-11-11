#!/bin/bash
#
# requires:
#  bash
#  s3cmd, git, sed
#
# imports:
#  utils: checkroot
#

function add_repo_options() {
  release_id=${release_id:-}

  s3_backet=${s3_backet:-dlc.wakame.axsh.jp}
  repo_base_path=${repo_base_path:-packages/rhel/6}
  repo_base_uri=${repo_base_uri:-s3://${s3_backet}/${repo_base_path}}
}

function check_repo_dir() {
  local opsroot_dir=$1 release_id=$2
  [[ -n "${opsroot_dir}" ]] || { echo "[ERROR] invalid argument (repo:${LINENO})" >&2; return 1; }
  [[ -n "${release_id}"  ]] || { echo "[ERROR] invalid argument (repo:${LINENO})" >&2; return 1; }

  [[ -d "${opsroot_dir}/${release_id}" ]] && {
    echo "[ERROR] already built: ${release_id}" >&2
    return 1
  } || :
}

function upload_repo() {
  local opsroot_dir=$1 release_id=$2 branch_name=${3:-$(git branch --no-color | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/')}
  [[ -n "${opsroot_dir}" ]] || { echo "[ERROR] invalid argument (repo:${LINENO})" >&2; return 1; }
  [[ -n "${release_id}"  ]] || { echo "[ERROR] invalid argument (repo:${LINENO})" >&2; return 1; }

  [[ -f "${opsroot_dir}/${release_id}.tar.gz" ]] || { echo "[ERROR] file not found: ${opsroot_dir}/${release_id}.tar.gz (repo:${LINENO})" >&2; return 1; }
  [[ -d "${opsroot_dir}/${release_id}/"       ]] || { echo "[ERROR] directory not found ${opsroot_dir}/${release_id}/ (repo:${LINENO})"   >&2; return 1; }

  local s3_cmd_opts="--acl-public --check-md5"

  s3cmd sync ${opsroot_dir}/${release_id}.tar.gz ${repo_base_uri}/${branch_name}/         ${s3_cmd_opts}
  s3cmd sync ${opsroot_dir}/${release_id}        ${repo_base_uri}/${branch_name}/         ${s3_cmd_opts}
  s3cmd sync ${opsroot_dir}/${release_id}/       ${repo_base_uri}/${branch_name}/current/ ${s3_cmd_opts} --delete-removed
}

function spot_build() {
  local opsroot_dir=$1
  [[ -n "${opsroot_dir}" ]] || { echo "[ERROR] invalid argument (repo:${LINENO})" >&2; return 1; }

  ${opsroot_dir}/spot-build.sh
}

function build_repo() {
  local opsroot_dir=$1 release_id=$2 branch_name=${3:-$(git branch --no-color | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/')}
  [[ -n "${opsroot_dir}" ]] || { echo "[ERROR] invalid argument (repo:${LINENO})" >&2; return 1; }
  [[ -n "${release_id}"  ]] || { echo "[ERROR] invalid argument (repo:${LINENO})" >&2; return 1; }

  spot_build ${opsroot_dir}
}

function create_repo() {
  local opsroot_dir=$1
  [[ -n "${opsroot_dir}" ]] || { echo "[ERROR] invalid argument (repo:${LINENO})" >&2; return 1; }
  checkroot || return 1

  add_repo_options
  check_repo_dir ${opsroot_dir} ${release_id} || return 1

  build_repo     ${opsroot_dir} ${release_id} ${branch_name}
  upload_repo    ${opsroot_dir} ${release_id} ${branch_name}
}
