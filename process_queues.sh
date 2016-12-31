#!/bin/bash
export HOME=/home/cottagelabs
if [ -d $HOME/.rbenv ]; then
  export PATH="$HOME/.rbenv/bin:$PATH"
  eval "$(rbenv init -)"
fi

# Now launch the app
cd /var/hullsync/
nohup bundle exec rake QUEUE=* RAILS_ENV=production environment resque:work &

