#!/bin/bash
if [ -z "$GITHUB_API_TOKEN" ]; then
  echo "Error: GITHUB_API_TOKEN is not set!"
  exit 1
fi

while [ $# -gt 0 ]
do
  case "$1" in
    -f) service_file="$2"; shift;;
    -n) service_name="$2"; shift;;
    -b) build_num="$2"; shift;;
    -t) branch="$2"; shift;;
    -h)
        echo >&2 "usage: $0 -t branch -b build -f service_file -n service_name"
        exit 1;;
     *) break;; # terminate while loop
  esac
  shift
done

set -o xtrace

# create branch, if missing in gaia-fleet
master_sha=$(curl --fail -S -L "https://api.github.com/repos/gaia-adm/gaia-fleet/git/refs/heads/master" | jq .object.sha | tr -d '"')
branch_missing=$(curl -I -s https://api.github.com/repos/gaia-adm/gaia-fleet/git/refs/heads/${branch} | grep '404 Not Found' | wc -l)
if (( $branch_missing > 0 )); then
	curl -XPOST -H "Authorization: token ${GITHUB_API_TOKEN}" -H "Content-Type: application/json" -H "Accept: application/vnd.github.v3+json" -d '{"ref": "refs/heads/'${branch}'", "sha": "'$master_sha'"}' https://api.github.com/repos/gaia-adm/gaia-fleet/git/refs
fi

f_sha=$(curl --fail -S -L "https://api.github.com/repos/gaia-adm/gaia-fleet/contents/${service_file}?ref=${branch}" | jq .sha | tr -d '"') && \
f_64=$(openssl enc -base64 -A -in <(sed "s/gaiaadm\/${service_name}/gaiaadm\/${service_name}:${build_num}-${branch}/g" ${service_file})) && \
curl --fail -S -i -X PUT -H "Authorization: token ${GITHUB_API_TOKEN}" -d "{\"path\": \"${service_file}\", \"message\": \"updating ${service_file} with the new image tag: ${build_num}-${branch}\", \"content\": \"${f_64}\", \"sha\": \"${f_sha}\", \"branch\": \"${branch}\"}" https://api.github.com/repos/gaia-adm/gaia-fleet/contents/${service_file}
