require 'nokogiri'

class DIPReader

  attr_accessor :dip_folder, :admin_struct, :content_struct, :metadata, :descriptions

  # example
  #dip_folder='/Users/martyn/Desktop/DIP/test_package_4_A.Ranganathan_2016-09-03T04_26_09-07_00-53f798ca-4076-4d77-92bd-0f15e0f6a11e'


  def initialize(dip_folder)
    unless Dir.exists?(dip_folder)
      raise("Cannot find DIP folder: #{dip_folder}")
    end

    @dip_folder = dip_folder
    mets_file = Dir.glob(File.join(@dip_folder, "METS.*.xml")).first

    if mets_file && File.exists?(mets_file)
      # Read the METS xml file
      mets_xml = File.open(mets_file) { |f| Nokogiri::XML(f) }

      @admin_struct = mets_xml.at_xpath("mets:mets/mets:structMap/mets:div[@TYPE='Directory']/mets:div[@LABEL='objects' and @TYPE='Directory']/mets:div[@LABEL='admin' and @TYPE='Directory']")
      @content_struct = mets_xml.at_xpath("mets:mets/mets:structMap/mets:div[@TYPE='Directory']/mets:div[@LABEL='objects' and @TYPE='Directory']/mets:div[@LABEL='content' and @TYPE='Directory']")

      @metadata = parse_admin_file("admin_metadata.json")
      description = parse_admin_file("description.json")
      if description.is_a?(Array)
        @descriptions = description
      else
        @descriptions = [description] # ensure descriptions is always an array to make processing simpler
      end

      @descriptions.each do |description|
        if description["filename"].present?
          file_references = find_file_references(description["filename"])

          puts "\nVISIBLE FILES:"
          puts description["visibleFiles"]

          puts "FILE REFERENCES:"
          puts file_references

          if description["visibleFiles"].present?
            if description["visibleFiles"] == ["all"]
              puts "ALL FILES!"
              description["fileReferences"] = file_references
            else
              # filter the file references to only those on the visible list
              description["fileReferences"] = file_references.find_all{|ref| description["visibleFiles"].include?(ref.keys.first)}
            end
          end

          description["uuids"] = file_references.map{|x| x.values.first[:uuid]}
        end
      end

    else
      raise("Cannot find METS xml file in: #{dip_folder}")
    end
  end



  def find_file_by_uuid(uuid)
    if uuid.present?
      Dir.glob(File.join(dip_folder, "objects", uuid_to_string(uuid) + "-*" )).first
    else
      nil
    end
  end

  def uuid_to_string(uuid)
    uuid.value.sub("file-","")
  end


  def parse_admin_file(admin_filename)
    uuid = @admin_struct.at_xpath("mets:div[@LABEL='#{admin_filename}' and @TYPE='Item']/mets:fptr/@FILEID")

    unless uuid.present?
      raise "UUID not found for: #{admin_filename}"
    end

    full_filename = find_file_by_uuid(uuid)
    unless File.exists?(full_filename)
      raise "File does not exist: #{full_filename}"
    end

    return File.open(full_filename) { |f| JSON.parse(f.read) }
  end



  def find_file_references(content_filename)
    div = @content_struct.at_xpath("mets:div[@LABEL='#{content_filename}']")
    if div.nil?
      []
    else
      if div.at_xpath("@TYPE").value == "Directory"
        div.xpath("mets:div").map do |item|
          build_file_reference(item.attribute("LABEL").value, item.at_xpath("mets:fptr/@FILEID"))
        end
      else
        [ build_file_reference(div.attribute("LABEL").value, div.at_xpath("mets:fptr/@FILEID")) ]
      end
    end
  end

  def build_file_reference(name, uuid)
    if uuid.present?
      {name => {uuid: uuid_to_string(uuid), filename: find_file_by_uuid(uuid)}}
    else
      nil
    end
  end
end
