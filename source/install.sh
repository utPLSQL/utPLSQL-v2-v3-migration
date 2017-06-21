#!/bin/bash

set -ev

cd "$(dirname "$(readlink -f "$0")")"

sqlplus -L -S ut3/XNtxj8eEgA6X6b6f @install.sql utp ut3
