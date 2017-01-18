require "resque/tasks"

task "resque:setup" => :environment


# see http://stackoverflow.com/questions/5880962/how-to-destroy-jobs-enqueued-by-resque-workers - old version
# see https://github.com/defunkt/resque/issues/49
# see http://redis.io/commands - new commands
desc 'Clear pending tasks'
task "resque:clear" => :environment do
  queues = Resque.queues
  queues.each do |queue_name|
    puts "Clearing #{queue_name}..."
    Resque.remove_queue("queue:#{queue_name}")
  end

  puts 'Clearing delayed...'
  Resque.redis.keys('delayed:*').each do |key|
    Resque.redis.del key.to_s
  end
  Resque.redis.del 'delayed_queue_schedule'

  puts 'Clearing stats...'
  Resque.redis.set 'stat:failed', 0
  Resque.redis.set 'stat:processed', 0

  puts 'Clearing zombie workers...'
  Resque.workers.each(&:prune_dead_workers)
end