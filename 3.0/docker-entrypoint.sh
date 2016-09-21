#!/bin/bash
set -e

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

createAdminAccounts() {
  echo "creating admin accounts";
  mongod --port 27017 --replSet "rs" --fork --logpath /data/db/mongodb.log
  sleep 8
  echo 2222222
  export SITE_USR_ADMIN_PWD='xxx';
  export SITE_KUKNITO_PWD='aaa';
  export SITE_OPLOGREADER_PWD='ooo';
  export SITE_ROOT_PWD='yyy';
  echo 3333333
  mongo admin --eval "db.createUser({user:'siteUserAdmin', pwd:'$SITE_USR_ADMIN_PWD',roles: [{role:'userAdminAnyDatabase', db:'admin'}, 'readWrite' ]})";
  mongo admin --eval "db.createUser({user:'kuknito', pwd:'$SITE_KUKNITO_PWD',roles: [{role:'readWrite', db:'kuknito'}]})";
  mongo admin --eval "db.createUser({user:'oplogReader', pwd:'$SITE_OPLOGREADER_PWD',roles: [{role:'read', db:'local'}]})";
  mongo admin --eval "db.createUser({user:'siteRootAdmin', pwd:'$SITE_ROOT_PWD',roles: [{role:'root', db:'admin'}, 'readWrite' ]})";
  echo 4444444
  sleep 3
  echo "exiting mongo (will start again)";
  mongo admin --eval "db.shutdownServer({ force: true })";
  sleep 3
  echo 5555555
  echo "admin accounts created";
}

createAdminAccounts
sleep 8
exec "$@"
