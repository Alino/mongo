#!/bin/bash
set -e

createAdminAccounts() {
  echo "creating admin accounts";
  mongod --port 27017
  SITE_USR_ADMIN_PWD='xxx';
  SITE_ROOT_PWD='yyy';
  mongo admin --eval "db.createUser({user:'siteUserAdmin', pwd:'$SITE_USR_ADMIN_PWD',roles: [{role:'userAdminAnyDatabase', db:'admin'}, 'readWrite' ]})";
  mongo admin --eval "db.createUser({user:'siteRootAdmin', pwd:'$SITE_ROOT_PWD',roles: [{role:'root', db:'admin'}, 'readWrite' ]})";
  echo "exiting mongo (will start again)";
  mongo admin --eval "db.shutdownServer()";
  echo "admin accounts created";
}

if [ "${1:0:1}" = '-' ]; then
	set -- mongod "$@"
fi

# allow the container to be started with `--user`
if [ "$1" = 'mongod' -a "$(id -u)" = '0' ]; then
	chown -R mongodb /data/configdb /data/db
	exec gosu mongodb "$BASH_SOURCE" "$@"
fi

if [ "$1" = 'mongod' ]; then
	numa='numactl --interleave=all'
	if $numa true &> /dev/null; then
		set -- $numa "$@"
	fi
fi

exec createAdminAccounts && "$@"
