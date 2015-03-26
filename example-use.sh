#!/bin/bash

set -e
set -u

CF_USERNAME='cf-user'
CF_PASSWORD='some-secret'
CF_API='api.sys.example.com'
CF_APP_DOMAIN='apps.examle.com'

## This part will push the app to CF.
## Ignore if manually done.

r=$RANDOM
APP_NAME="postgresql-smoketest-app-$r"

export PATH=$PATH:/var/vcap/packages/cf_cli_6.10.0/bin

cd /var/vcap/packages/postgresql_smoketest

cf api $CF_API
cf auth $CF_USERNAME $CF_PASSWORD
cf create-org smoketest
cf target -o smoketest
cf create-space postgresql
cf target -s postgresql
cf push $APP_NAME

cf create-service postgresql-db development postgresql-smoketest-service
cf bind-service $APP_NAME postgresql-smoketest-service
cf restage $APP_NAME

##
## App is running in CF with a PostgreSQL service instance bound to it.

APP_URL="http://$APP_NAME.$CF_APP_DOMAIN"
DATABASE_NAME='test_db'
DATABASE_NAME_2='test_db_2'
USER1='user1'
USER2='user2'

check_status() {
  curl $@
  local RESPONSE=$?

  if [ "$RESPONSE" == "0" ]
  then
    echo "Status: curl $@ : PASSED"
  else
    echo "Status: curl $@ : FAILED"
    kill -s TERM $TOP_PID
    exit 1
  fi
}

## Verify we can query basic "SELECT 'ok'"
tests[0]="$APP_URL"

## Create a database 'test_db'
tests[1]="$APP_URL/create-database/$DATABASE_NAME -X PUT -d ''"

## Create 'user1' and grant all privileges of 'test_db'.
tests[2]="$APP_URL/create-user/$USER1/for/$DATABASE_NAME -X PUT -d ''"

## Verify 'user1' can access 'test_db'
tests[3]="$APP_URL/select-ok/on/$DATABASE_NAME/as/$USER1"

## Create 'test_db_2'. Not necessary, but creating user is configured to be given access to some database.
tests[4]="$APP_URL/create-database/$DATABASE_NAME_2 -X PUT -d ''"

## Create 'user2' with access to 'test_db_2'.
tests[5]="$APP_URL/create-user/$USER2/for/$DATABASE_NAME_2 -X PUT -d ''"

for i in "${tests[@]}"
do
  echo $(check_status $i)
done


## Access database 'test_db' as 'user2'.
## Should raise an error.
RESPONSE=`curl $APP_URL/select-ok/on/$DATABASE_NAME/as/$USER2`
if [ "$RESPONSE" == "0" ]
then
  echo "Smoketests failed."
  kill -s TERM $TOP_PID
  exit 1
else
  echo "Smoketests passed."
fi

echo `curl $APP_URL/delete-user/$USER1 -X DELETE`
echo `curl $APP_URL/delete-user/$USER2 -X DELETE`
echo `curl $APP_URL/delete-database/$DATABASE_NAME -X DELETE`
echo `curl $APP_URL/delete-database/$DATABASE_NAME_2 -X DELETE`

cf unbind-service $APP_NAME postgresql-smoketest-service
cf delete-service postgresql-smoketest-service -f
cf delete $APP_NAME -f
cf delete-space postgresql -f

exit 0
