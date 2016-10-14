# require 'box_client'
class BagitProcessorJob
  @queue = :bagit_processor

  def self.perform(bagit_processing_dir)
    puts '3. ----------------------------------'
    puts 'In bagit processor'
    puts bagit_processing_dir
    # result = `bagit.py --md5 #{bagit_processing_dir}`
    # Resque.enqueue(ArchivematicaProcessorJob, bagit_processing_dir)
  end
end
