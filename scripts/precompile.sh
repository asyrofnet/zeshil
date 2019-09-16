#!/bin/bash

if [ $# -eq 0 ] ; then
  echo 'no argument supplied, running precompile'
  export RAILS_ENV=production

  rake tmp:cache:clear
  rails assets:clean
  rails assets:precompile
else
  if [ x$1 == "xy" ] ; then
    echo "argument == y, running precompile"
    export RAILS_ENV=production

    rake tmp:cache:clear
    rails assets:clean
    rails assets:precompile
  else
    echo "argument != y, so not running precompile"
  fi
fi
