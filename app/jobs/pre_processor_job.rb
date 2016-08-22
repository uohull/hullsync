class PreProcessorJob
  @queue = :pre_processor

  def self.perform(file_id, original_file_name)
    puts file_id, original_file_name
  end
end
