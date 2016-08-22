class WatchProcessorJob
  @queue = :watcher

  def self.perform(message)
    puts message
  end
end
