#!/bin/bash

set -ev

cd "$(dirname "$(readlink -f "$0")")"

sqlplus -L -S / as sysdba @install.sql utp ut3
