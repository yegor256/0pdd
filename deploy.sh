#!/bin/bash
set -e

cd $(dirname $0)
bundle update
sed -i -s 's|Gemfile.lock||g' .gitignore
cp /code/home/assets/0pdd/config.yml .
git add config.yml
git add Gemfile.lock
git add .gitignore
git commit -m 'config.yml for heroku'
trap 'git reset HEAD~1 && rm config.yml' EXIT
git push heroku master -f

