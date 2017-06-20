#!/bin/bash
set -ev

cd "$(dirname "$(readlink -f "$0")")"

sqlplus -L -S ${DB_USER}/${DB_PASS} <<SQL
whenever sqlerror exit failure rollback
whenever oserror  exit failure rollback

@migration_test/test_migration.pks
@migration_test/test_migration.pkb

exit
SQL
