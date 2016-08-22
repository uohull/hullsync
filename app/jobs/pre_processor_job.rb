require 'helpers'
class PreProcessorJob
  @queue = :pre_processor

  def self.perform(folder_id, original_filename)
    puts 'PRE-PROCESSING'
    puts folder_id, original_filename
    box_client = BoxClient.new
    # Get folder metadata
    folder = box_client.folder_from_id(folder_id)
    box_user_dir = File.join(ENV['BOX_ROOT_DIR'], folder.name)
    bagit_processing_dir = File.join(ENV['BAGIT_ROOT_DIR'], folder.name)
    puts box_user_dir, bagit_processing_dir
    if copy_folder(box_user_dir, bagit_processing_dir)
      create_metadata_files
      puts 'Add to queues'
      Resque.enqueue(InformUserJob, folder_id, original_filename)
      Resque.enqueue(BagitProcessorJob, bagit_processing_dir)
    else
      puts 'error copying'
    end
    puts '~'*60
  end

end

