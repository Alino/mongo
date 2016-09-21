#!/bin/bash
set -e

createAdminAccounts() {
  echo "creating admin accounts";
  gosu mongodb bash -c 'touch /data/mongodb.log'
  gosu mongodb bash -c 'mongod --port 27017 --fork --logpath /data/mongodb.log'
  sleep 8
  echo 2222222
  export SITE_USR_ADMIN_PWD='xxx'
  echo 3333333
  export SITE_ROOT_PWD='yyy';
  echo 4444444
  mongo admin --eval "db.createUser({user:'siteUserAdmin', pwd:'$SITE_USR_ADMIN_PWD',roles: [{role:'userAdminAnyDatabase', db:'admin'}, 'readWrite' ]})";
  echo 5555555
  sleep 3
  mongo admin --eval "db.createUser({user:'siteRootAdmin', pwd:'$SITE_ROOT_PWD',roles: [{role:'root', db:'admin'}, 'readWrite' ]})";
  echo 6666666
  sleep 3
  echo "exiting mongo (will start again)";
  echo 7777777
  mongo admin --eval "db.shutdownServer()";
  sleep 3
  echo 8888888
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

createAdminAccounts
sleep 8
exec "$@"
