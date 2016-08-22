require 'box_client'
class WatchProcessorJob
  @queue = :watcher

  def self.perform(message)
    if message['event_type'] == 'added_collaborator'
      # if event is 'added collaborator' act on it
      box_client = BoxClient.new
      # Get folder metadata
      folder_id = message['item_id']
      folder = box_client.folder_from_id(folder_id)
      # Rename folder
      original_filename = folder.name
      box_client.rename_folder(folder, original_filename, status='processing')
      Resque.enqueue(PreProcessorJob, folder_id, original_filename)
    end
  end
end
