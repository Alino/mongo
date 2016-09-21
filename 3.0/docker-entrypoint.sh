#!/bin/bash
set -e

# start mongod without auth and create admin accounts
{
  exec echo "creating admin accounts";
  exec mongod --port 27017
  SITE_USR_ADMIN_PWD='xxx';
  SITE_ROOT_PWD='yyy';
  exec mongo admin --eval "db.createUser({user:'siteUserAdmin', pwd:'$SITE_USR_ADMIN_PWD',roles: [{role:'userAdminAnyDatabase', db:'admin'}, 'readWrite' ]})";
  exec mongo admin --eval "db.createUser({user:'siteRootAdmin', pwd:'$SITE_ROOT_PWD',roles: [{role:'root', db:'admin'}, 'readWrite' ]})";
  exec echo "exiting mongo (will start again)";
  exec mongo admin --eval "db.shutdownServer()";
  exec echo "admin accounts created";
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

exec "$@"
