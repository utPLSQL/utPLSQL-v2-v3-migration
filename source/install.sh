#!/bin/bash

set -ev

cd "$(dirname "$(readlink -f "$0")")"

"$SQLCLI" sys/$ORACLE_PWD@//$CONNECTION_STR AS SYSDBA @install.sql utp ut3
