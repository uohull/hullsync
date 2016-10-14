# require 'box_client'
class BagitProcessorJob
  @queue = :bagit_processor

  def self.perform(bagit_processing_dir)
    puts "3. ----------------------------------"
    puts "In bagit processor"
    # TODO:
    puts bagit_processing_dir
  end
end
