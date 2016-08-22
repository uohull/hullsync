require 'box_client'
class WatchProcessorJob
  @queue = :watcher

  def self.perform(message)
    puts message
    if message['event_type'] == 'added_collaborator'
      puts 'PRE-PROCESSING'
      # if event is 'added collaborator' act on it
      box_client = BoxClient.new()
      # Get folder metadata
      folder_id = message['item_id']
      puts folder_id
      folder = box_client.folder_from_id(folder_id)
      puts folder
      # Rename folder
      original_filename = folder.name
      box_client.rename_folder(folder, original_filename, status='processing')
      Resque.enqueue(PreProcessorJob, folder_id, original_filename)
    end
    puts '-'*60
  end
end
