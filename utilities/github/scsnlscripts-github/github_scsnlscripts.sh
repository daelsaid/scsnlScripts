#!/bin/bash

cd /oak/stanford/groups/menon/scsnlscripts/;

git add -A --ignore-errors .;
git commit -m "update on `date \"+%Y-%m-%d\"`";
git pull origin master;
git push origin master;
