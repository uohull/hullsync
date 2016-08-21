require 'boxr'

# ENV file should be filled. Read box_env.md


class BoxClient

  def initialize
    self.access_token = ''
    self.refresh_token = ''
    self.client = oauth_init
  end

  def save_tokens(access, refresh)
    File.write('.box_access_token', access)
    File.write('.box_refresh_token', refresh)
  end

  def oauth_init
    token_refresh_callback = lambda {|access, refresh, identifier| save_tokens(access, refresh)}
    self.access_token = File.read('.box_access_token')
    self.refresh_token = File.read('.box_refresh_token')
    self.client = Boxr::Client.new(self.access_token, refresh_token: self.refresh_token, client_id: ENV['BOX_CLIENT_ID'], client_secret: ENV['BOX_CLIENT_SECRET'], &token_refresh_callback)
  end

  def jwt_enterprise_init
    self.client = Boxr::Client.new('', jwt_private_key:  File.read(ENV['JWT_PRIVATE_KEY_FILE']))
  end

  def jwt_user_init
    self.client = Boxr::Client.new('', jwt_private_key: File.read(ENV['JWT_PRIVATE_KEY_FILE']), as_user: ENV['BOX_USER_ID'], enterprise_id: nil)
  end

  def folder_contents(path=nil)
    unless path
      self.client.+-

    else
      self.client.folder_items(path)
    end
  end

  def folder_from_id(id)
  self.client.folder_from_id(id)
  end

  def rename_folder(folder, original_name, status='processing')
    self.client.folder_from_id(id)
    new_name = "#{original_name}_#{folder.created_by.name}_#{status}"
    self.client.update_folder(folder, name: new_name)
  end

  def remove_my_collaboration(folder)
    collaborations = self.client.folder_collaborations(folder)
    collaborations.each do |collaboration|
      if collaboration.type == 'collaboration' && collaboration.accessible_by.login == 'archivematica@hull.ac.uk'
        self.client.remove_collaboration(collaboration)
      end
    end
  end

  def user_id
    # for jwt to get id when initialized with oauth
    self.client.current_user.id
  end

  def refresh_oauth_tokens()
    # For managing oauth token generation
    rt = Boxr::refresh_tokens(self.refresh_token, client_id: ENV['BOX_CLIENT_ID'], client_secret: ENV['BOX_CLIENT_SECRET'])
    save_tokens(rt.access_token, rt.refresh_token)
    #TODO: re-initialize client
  end
end