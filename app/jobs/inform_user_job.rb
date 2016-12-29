require 'box_client'
class InformUserJob
  @queue = :inform_user

  def self.perform(folder_id, original_filename)
    puts '3. ---------------------------'
    puts 'Inform user'
    puts folder_id
    puts original_filename
    box_client = BoxClient.new
    # Get folder metadata
    folder = box_client.folder_from_id(folder_id)
    # Rename folder
    box_client.rename_folder(folder, original_filename, status='archiving')
    # Remove collaboration
    box_client.remove_my_collaboration(folder)
  end
end
