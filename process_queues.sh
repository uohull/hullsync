#!/bin/bash
export HOME=/home/cottagelabs
if [ -d $HOME/.rbenv ]; then
  export PATH="$HOME/.rbenv/bin:$PATH"
  eval "$(rbenv init -)"
fi

# Now launch the app
cd /var/hullsync/

# clear old queues
nohup bundle exec rake RAILS_ENV=production resque:clear

# start workers in background
nohup bundle exec rake QUEUE=* RAILS_ENV=production environment resque:work &

