#!/bin/bash
#
# requires:
#  bash
#  git, s3cmd
#
# imports:
#  utils: extract_args
#  git: release_id
#  repo: add_repo_options
#
# usage:
#  $ tag-watcher.sh --git-repo-name=wakame-vdc
#  $ tag-watcher.sh --git-repo-name=wakame-vdc --src-branch-name=master --dst-branch-name=production
#
set -e

## private functions

function register_options() {
  add_repo_options

  # git
  git_repo_name=${git_repo_name:-wakame-vdc}
  src_branch_name=${src_branch_name:-master}
  dst_branch_name=${dst_branch_name:-production}

  git_repo_uri=${git_repo_uri:-git@github.com:axsh/${git_repo_name}.git}
  workspace_path=${workspace_path:-${abs_dirname}/${git_repo_name}}

  src_repo_base_uri=${src_repo_base_uri:-${repo_base_uri}/${src_branch_name}}
  dst_repo_base_uri=${dst_repo_base_uri:-${repo_base_uri}/${dst_branch_name}}
}

function check_tag() {
  local tag_name=$1
  [[ -n "${tag_name}" ]] || { echo "[ERROR} invalid argument: tag_name" >&2: return 1; }

  git checkout ${tag_name} 2>/dev/null

  [[ -f rpmbuild/SPECS/wakame-vdc.spec ]] || {
    echo "[WARN] can't build rpm because .spec file does not exist: rpmbuild/SPECS/wakame-vdc.spec." >&2
    return 1
  }

  local release_id=$(release_id)
  [[ "$(s3cmd ls ${src_repo_base_uri}/${release_id}/ | wc -l)" == "0" ]] && {
    echo "[WARN] should build ${src_repo_base_uri}/${release_id}/ before sync rpms." >&2
    return 1
  } || {
    echo "[INFO] should sync ${src_repo_base_uri}/${release_id}/ to ${dst_repo_base_uri}/${tag_name}/" >&2
    echo "[INFO] should sync ${src_repo_base_uri}/${release_id}/ to ${dst_repo_base_uri}/current/"     >&2
  }
}

### read-only variables

readonly abs_dirname=$(cd $(dirname $0) && pwd)

### variables

## include files

. ${abs_dirname}/functions/utils.sh
. ${abs_dirname}/functions/repo.sh
. ${abs_dirname}/functions/git.sh

### prepare

extract_args $*
register_options

[[ -d "${workspace_path}" ]] || git clone ${git_repo_uri} ${workspace_path}
cd     ${workspace_path}
git fetch

while read tag_name; do
  echo "[DEBUG] tag:${tag_name}" >&2
  check_tag ${tag_name} || continue
done < <(git tag -l)
