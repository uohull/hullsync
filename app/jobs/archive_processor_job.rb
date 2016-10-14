# require 'box_client'
class ArchiveProcessorJob
  @queue = :bagit_processor

  def self.perform(bagit_processing_dir)
    puts '3. ----------------------------------'
    puts 'In bagit processor'
    puts bagit_processing_dir
    result = `bagit.py --md5 #{bagit_processing_dir}`
    # TODO archivematica processor - run Archivematica tools and get pid
    # Resque.enqueue(ArchivematicaStatusJob, pid)
  end
end
