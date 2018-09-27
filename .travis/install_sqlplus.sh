#!/bin/bash
set -e

SQLCL_FILE=instantclient-sqlplus-linux.x64-18.3.0.0.0dbru.zip
CLIENT=instantclient-basiclite-linux.x64-18.3.0.0.0dbru.zip

cd .travis

if [[ ! -f $CACHE_DIR/$SQLCL_FILE || ! -f $CACHE_DIR/$CLIENT ]]; then
    npm install -g phantomjs-prebuilt casperjs
    bash download.sh -p sqlplus
    bash download.sh -p instantclient
    mv $SQLCL_FILE $CACHE_DIR
    mv $CLIENT     $CACHE_DIR
else
    echo "Installing instantclient from cache..."
fi;

# Install sqlcl.
unzip -q $CACHE_DIR/$CLIENT     -d $HOME
unzip -q $CACHE_DIR/$SQLCL_FILE -d $HOME

# Check if it is installed correctly.
$HOME/instantclient_18_3/sqlplus -v
