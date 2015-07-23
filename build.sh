#! /usr/bin/env bash

source `dirname $0`/common.sh

PKG=$1

notice "Installing Ruby 1.9.1"
sudo apt-get install ruby1.9.1 -qq

export DEBIAN_FRONTEND=noninteractive
notice "Fetching apt-source-whitelist data"
wget https://raw.githubusercontent.com/travis-ci/apt-source-whitelist/master/ubuntu.json
notice "Applying apt-source-whitelist data"
ruby1.9.1 -rjson add_sources.rb
mkdir -p /var/tmp/deb-sources
cd /var/tmp/deb-sources
sudo apt-get update -qq &>/dev/null

notice "Fetching source package for ${PKG}"
apt-get source ${PKG} 2>&1 | tee apt-get-result.log

if egrep 'Unable to find a source package for' apt-get-result.log 2>/dev/null; then
	exit $EXIT_SOURCE_NOT_FOUND
fi

for d in $(find . -name debian) ; do
  pushd $d &>/dev/null && \
    grep ^Package control | awk -F: '{ print $2 }' | xargs echo ;
  popd &>/dev/null ;
done | xargs echo > packages

if grep -R -i -H -C5 -E --color 'set(uid|euid|gid)' --exclude install-sh . 2>/dev/null; then
	warn "Suspicious bits found"
	exit $EXIT_SOURCE_HAS_SETUID
else
	notice "No setuid bits found"
	exit 0
fi
