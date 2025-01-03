#! /usr/bin/env bash

set -e
set -x

cd "$(dirname "${BASH_SOURCE[0]}")/../../"

mapfile -t filestocheck < <(find bin/ -type f)
for x in "${filestocheck[@]}"; do
  shellcheck conf/uno.conf bin/impl/util.sh bin/impl/load-env.sh bin/impl/commands.sh "$x"
done
