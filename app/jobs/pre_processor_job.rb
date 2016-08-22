require 'fileutils'

class PreProcessorJob
  @queue = :pre_processor

  def self.perform(folder_id, original_filename)
    puts folder_id, original_filename
    box_client = BoxClient.new
    # Get folder metadata
    folder = box_client.folder_from_id(folder_id)
    box_user_dir = File.join(ENV['BOX_ROOT_DIR'], folder.name)
    bagit_processing_dir = File.join(ENV['BAGIT_ROOT_DIR'], folder.name)
    copy_folder(box_user_dir, bagit_processing_dir)
    create_metadata_files
    Resque.enqueue(InformUserJob, folder_id, original_filename)
    Resque.enqueue(BagitProcessorJob, bagit_processing_dir)
  end

  def copy_folder(source, destination)
    return unless File.directory? (source)
    if File.directory?(destination)
      FileUtils.rm_rf(destination)
    end
    FileUtils.mkdir_p(destination)
    FileUtils.cp_r File.join(source, '.'), destination, :verbose => false
  end

  def create_metadata_files
    # TODO
  end
end
