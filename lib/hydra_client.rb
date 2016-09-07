require 'rubygems'
require 'mechanize'

class HydraClient

  attr_accessor :agent, :cookies

  HYDRA_LOGIN_URI = URI('https://hydra-test.hull.ac.uk/users/sign_in')
  CAS_SERVER = 'cas.hull.ac.uk'
  DEFAULT_SUBJECT = 'Research Data Spring'

  def initialize
    @agent = Mechanize.new
    @cookies = []

    raise("HYDRA_USERNAME is not set") unless ENV['HYDRA_USERNAME'].present?
    raise("HYDRA_PASSWORD is not set") unless ENV['HYDRA_PASSWORD'].present?
  end

  def authenticated?
    @agent.get(HYDRA_LOGIN_URI).uri.hostname != CAS_SERVER
  end

  def authenticate
    @agent.get(HYDRA_LOGIN_URI) do |page|

      # if we are already logged in, then going to the Sign In page should NOT redirect us to the CAS server (cas.hull.ac.uk)
      if page.uri.hostname == CAS_SERVER
        # we are NOT signed in
        puts "Logging into Hydra..."

        form = page.forms.first
        form.username = ENV['HYDRA_USERNAME']
        form.password = ENV['HYDRA_PASSWORD']

        response = @agent.submit(form)

        if response.uri.hostname == CAS_SERVER
          raise "Failed to login to Hydra at #{HYDRA_LOGIN_URI} - check HYDRA_USERNAME and HYDRA_PASSWORD"
        end

        @cookies = @agent.cookie_jar.store.map {|i|  i}
      else
        # we are already authenticated
        puts "Already authenticated"
      end
    end
    nil
  end

  def create_dataset(description, uuid="TODO - UUID HERE", files=[])
    # make sure we are authenticated
    authenticate

    # load the create new dataset form
    @agent.get("/datasets/new") do |page|
      response = page.form_with(action: "/datasets") do |form|
        # enter the form values
        form.field_with(name: "dataset[person_name][]").value = description["creator"].first
        form.field_with(name: "dataset[person_role_text][]").value = "Creator"

        if description["creator"].count > 1
          for i in 1...(description["creator"].count)
            form.add_field!("dataset[person_name][]", description["creator"][i])
            form.add_field!("dataset[person_role_text][]", "Creator")
          end
        end

        form.field_with(name: "dataset[title]").value = description["title"]
        form.field_with(name: "dataset[subject_topic][]").value = DEFAULT_SUBJECT
        form.field_with(name: "dataset[description]").value = description["description"]
        form.field_with(name: "dataset[citation][]").value = uuid

        if description["citation"].present?
          form.add_field!("dataset[citation][]", description["citation"])
        end

      end.submit

      puts "DATASET SUBMITTED!"
      puts response.uri

      # now upload the files
      files.each do |file|
        file_response = response.form_with(action: "/files") do |form|
          form.file_upload_with(name: "Filedata[]").file_name = file
        end.submit

        puts "FILE SUBMITTED!"
        puts file_response.uri
      end


    end

    nil
  end

end