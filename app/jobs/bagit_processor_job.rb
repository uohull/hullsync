# require 'box_client'
class BagitProcessorJob
  @queue = :bagit_processor

  def self.perform(bagit_processing_dir)
    puts 'BAGIT PROCESSOR JOB'
    puts bagit_processing_dir
  end
end
