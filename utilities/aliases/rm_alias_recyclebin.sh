#!/bin/bash

RECYCLE_FILE=$1
RECYCLE_PATH=/scratch/PI/menon/recycleBin/

echo Copying files to recycle bin...

echo $(date +%Y_%m_%d)

FULL_PATH=$RECYCLE_PATH/$(date +%Y_%m_%d)

if [ ! -d "$FULL_PATH" ]; then
  echo Making $(date +%Y_%m_%d) directory
  mkdir "$FULL_PATH"
  chmod 775 -R "$FULL_PATH"
fi

cp -r $RECYCLE_FILE $FULL_PATH;

/bin/rm -rf $RECYCLE_FILE;
