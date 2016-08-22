class WatchProcessorJob
  @queue = :watcher

  def self.perform(file_id)
    puts file_id
  end
end
