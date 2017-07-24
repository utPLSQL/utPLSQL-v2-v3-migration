#!/bin/bash

set -ev

cd "$(dirname "$(readlink -f "$0")")"

sqlplus -L -S / as sysdba @uninstall.sql utp ut3
