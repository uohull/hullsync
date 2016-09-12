require 'rubygems'
require 'mechanize'

class HydraClient

  attr_accessor :agent, :cookies

  HYDRA_LOGIN_URI = URI('https://hydra-test.hull.ac.uk/users/sign_in')
  CAS_SERVER = 'cas.hull.ac.uk'
  DEFAULT_SUBJECT = 'Research Data Spring'
  DEFAULT_PUBLISHER = 'Unknown'
  DEFAULT_JOURNAL_TITLE = 'Unknown'

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

  def create(object_type, description, aip_uuid)
    # make sure we are authenticated
    authenticate
    case object_type.try(:upcase)
      when "JOURNAL_ARTICLE"
        response = create_journal_article(description, aip_uuid)
      when "BOOK"
        response = create_book(description, aip_uuid)
      else # everything else defaults to "DATASET"
        response = create_dataset(description, aip_uuid)
    end

    # check if we successfully created the object - if so, upload any files and submit
    if response.uri.path.ends_with?("/edit")

      file_response = create_files(description, response)
      submit_to_qa(file_response)
    else
      puts "ERROR failed to create new #{object_type}: #{response.uri}"
      puts response.inspect
      puts response.header
    end
    nil
  end


  private

  def create_dataset(description, aip_uuid)
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
        form.field_with(name: "dataset[subject_topic][]").value = description["subject"] || DEFAULT_SUBJECT
        form.field_with(name: "dataset[description]").value = description["description"]

        if description["citation"].present?
          form.field_with(name: "dataset[citation][]").value = description["citation"]
        end
        form.field_with(name: "dataset[see_also][]").value = "Archivematica AIP UUID: #{aip_uuid}"
        form.field_with(name: "dataset[location_coordinates]").value = "" # for some reason, a newline character is added to this box
      end.submit
      puts "Dataset: #{response.uri}"
      return response
    end
  end


  def create_journal_article(description, aip_uuid)
    # load the create new journal_article form
    @agent.get("/journal_articles/new") do |page|
      response = page.form_with(action: "/journal_articles") do |form|
        # enter the form values
        form.field_with(name: "journal_article[person_name][]").value = description["creator"].first
        form.field_with(name: "journal_article[person_role_text][]").value = "Author"

        if description["creator"].count > 1
          for i in 1...(description["creator"].count)
            form.add_field!("journal_article[person_name][]", description["creator"][i])
            form.add_field!("journal_article[person_role_text][]", "Creator")
          end
        end

        form.field_with(name: "journal_article[title]").value = description["title"]
        form.field_with(name: "journal_article[journal_title]").value = description["journal_title"] || DEFAULT_JOURNAL_TITLE
        form.field_with(name: "journal_article[subject_topic][]").value = description["subject"] || DEFAULT_SUBJECT
        form.field_with(name: "journal_article[abstract]").value = description["description"]
        form.field_with(name: "journal_article[publisher]").value = description["publisher"] || DEFAULT_PUBLISHER
        form.field_with(name: "journal_article[journal_date_other]").value = description["date_accepted"] || Date.today.strftime('%Y-%m-%d')
        form.field_with(name: "journal_article[journal_publications_note]").value = "Archivematica AIP UUID: #{aip_uuid}"
      end.submit
      puts "Journal Article: #{response.uri}"
      return response
    end
  end


  def create_book(description, aip_uuid)
    # load the create new book form
    @agent.get("/books/new") do |page|
      response = page.form_with(action: "/books") do |form|
        # enter the form values
        form.field_with(name: "book[person_name][]").value = description["creator"].first
        form.field_with(name: "book[person_role_text][]").value = "Author"

        if description["creator"].count > 1
          for i in 1...(description["creator"].count)
            form.add_field!("book[person_name][]", description["creator"][i])
            form.add_field!("book[person_role_text][]", "Author")
          end
        end

        form.field_with(name: "book[title]").value = description["title"]
        form.field_with(name: "book[subtitle]").value = description["subtitle"]
        form.field_with(name: "book[series_title]").value = description["series_title"]
        form.field_with(name: "book[subject_topic][]").value = description["subject"] || DEFAULT_SUBJECT
        form.field_with(name: "book[description]").value = description["description"]
        form.field_with(name: "book[see_also][]").value = "Archivematica AIP UUID: #{aip_uuid}"
      end.submit
      puts "Book: #{response.uri}"
      return response
    end
  end




  def create_files(description, response)
    file_response = response

    # now upload the files
    if description["fileReferences"].present?
      description["fileReferences"].each do |fileReference|
        file_response = file_response.form_with(action: "/files") do |form|
          form.file_upload_with(name: "Filedata[]").file_name = fileReference.values.first[:filename]
        end.submit

        puts "File uploaded: #{file_response.uri}"
      end
    end

    return file_response
  end


  def submit_to_qa(response)
    # Finally, submit the form
    container_id = response.form_with(action: "/files").field_with(name: "container_id").value

    response.form_with(action: "/resource_workflow/#{container_id}") do |form|
      form.click_button(form.button_with(type: "submit"))
    end

    puts "Submitted to Q&A: #{response.uri}"

  end
end