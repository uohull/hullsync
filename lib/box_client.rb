require 'boxr'


class BoxClient
  # ENV file should be filled. Read box_env.md

  def initialize
    @access_token = ''
    @refresh_token = ''
    @client = oauth_init
  end

  def save_tokens(access, refresh)
    File.write('.box_access_token', access)
    File.write('.box_refresh_token', refresh)
  end

  def oauth_init
    token_refresh_callback = lambda {|access, refresh, _identifier| save_tokens(access, refresh)}
    @access_token = File.read('.box_access_token')
    @refresh_token = File.read('.box_refresh_token')
    puts @access_token, @refresh_token
    # @client = Boxr::Client.new(@access_token, refresh_token: @refresh_token, client_id: ENV['BOX_CLIENT_ID'], client_secret: ENV['BOX_CLIENT_SECRET'], &token_refresh_callback)
    @client = Boxr::Client.new(@access_token, refresh_token: @refresh_token, &token_refresh_callback)
  end

  def jwt_enterprise_init
    @client = Boxr::Client.new('', jwt_private_key:  File.read(ENV['JWT_PRIVATE_KEY_FILE']))
  end

  def jwt_user_init
    @client = Boxr::Client.new('', jwt_private_key: File.read(ENV['JWT_PRIVATE_KEY_FILE']), as_user: ENV['BOX_USER_ID'], enterprise_id: nil)
  end

  def folder_contents(path=nil)
    (not path) ? @client.folder_items(Boxr::ROOT) : @client.folder_items(path)
  end

  def folder_from_id(id)
    @client.folder_from_id(id)
  end

  def rename_folder(folder, original_name, status='processing')
    @client.folder_from_id(id)
    new_name = "#{original_name}_#{folder.created_by.name}_#{status}"
    @client.update_folder(folder, name: new_name)
  end

  def remove_my_collaboration(folder)
    collaborations = @client.folder_collaborations(folder)
    collaborations.each do |collaboration|
      if collaboration.type == 'collaboration' && collaboration.accessible_by.login == 'archivematica@hull.ac.uk'
        @client.remove_collaboration(collaboration)
      end
    end
  end

  def user_id
    # for jwt to get id when initialized with oauth
    @client.current_user.id
  end

  def refresh_oauth_tokens
    # For managing oauth token generation
    rt = Boxr::refresh_tokens(@refresh_token, client_id: ENV['BOX_CLIENT_ID'], client_secret: ENV['BOX_CLIENT_SECRET'])
    save_tokens(rt.access_token, rt.refresh_token)
    #TODO: re-initialize client
  end
end
