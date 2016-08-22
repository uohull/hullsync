require 'helpers'
class PreProcessorJob
  @queue = :pre_processor

  def self.perform(folder_id, original_filename)
    box_client = BoxClient.new
    # Get folder metadata
    folder = box_client.folder_from_id(folder_id)
    box_user_dir = File.join(ENV['BOX_ROOT_DIR'], folder.name)
    new_name = folder.name
    if new_name.ends_with?('_processing')
      new_name.gsub!(/(.*)(_processing)(.*)/, '\1\3')
    end
    bagit_processing_dir = File.join(ENV['BAGIT_ROOT_DIR'], new_name)
    if copy_folder(box_user_dir, bagit_processing_dir)
      create_bagit_metadata_files
      Resque.enqueue(InformUserJob, folder_id, original_filename)
      Resque.enqueue(BagitProcessorJob, bagit_processing_dir)
    end
  end

end

