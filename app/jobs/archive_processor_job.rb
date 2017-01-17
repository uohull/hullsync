# require 'box_client'
class ArchiveProcessorJob
  @queue = :bagit_processor

  def self.perform(bagit_temp_dir)
    puts '3. ----------------------------------'
    puts 'In bagit processor'
    puts bagit_temp_dir

    # generate bag
    result = `bagit.py --md5 #{bagit_temp_dir}`

    # move to archivematica processing area
    FileUtils.move(bagit_temp_dir, ENV['BAGIT_ROOT_DIR'])

    Resque.enqueue(ArchivematicaStatusJob)
  end
end
