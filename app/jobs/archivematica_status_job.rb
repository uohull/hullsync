# require 'box_client'
class ArchivematicaStatusJob
  @queue = :archivematica_status

  def self.perform()
    puts '4. ----------------------------------'
    puts 'In archivematica status'

    puts 'Sleeping until DIP is ready  /var/archivematica/sharedDirectory/watchedDirectories/uploadedDIPs/'
    dip_folder = `/usr/local/bin/sleep_until_modified.sh /var/archivematica/sharedDirectory/watchedDirectories/uploadedDIPs/`
    puts 'New DIP :' + dip_folder
    Resque.enqueue(DIPProcessorJob, dip_folder)
  end
end
