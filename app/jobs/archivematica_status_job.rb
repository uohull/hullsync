# require 'box_client'
class ArchivematicaStatusJob
  @queue = :archivematica_status

  def self.perform(pid)
    puts '4. ----------------------------------'
    puts 'In archivematica status'
    # puts pid
    # TODO: run archivematica api get status
    # Resque.enqueue(DIPProcessorJob, dip_folder)
  end
end
