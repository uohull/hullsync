require 'nokogiri'
require 'hydra_client'

class DIPProcessorJob
  @queue = :dip_processor

  def self.perform(dip_folder)

    # example
    #dip_folder='/Users/martyn/Desktop/DIP/test_package_4_A.Ranganathan_2016-09-03T04_26_09-07_00-53f798ca-4076-4d77-92bd-0f15e0f6a11e'

    unless Dir.exists?(dip_folder)
      raise("Cannot find DIP folder: #{dip_folder}")
    end

    puts "Processing: #{dip_folder}"
    mets_file = Dir.glob(File.join(dip_folder, "METS.*.xml")).first

    if mets_file && File.exists?(mets_file)
      # Read the METS xml file
      mets_xml = File.open(mets_file) { |f| Nokogiri::XML(f) }

      admin_metadata = extract_admin_data(dip_folder, mets_xml, "admin_metadata.json")
      admin_description = extract_admin_data(dip_folder, mets_xml, "description.json")

      if admin_description.kind_of?(Array)

        admin_description.each do |description|



        end

      else

      end
      files = find_file_references(dip_folder, mets_xml,)



      #hydra=HydraClient.new
      #hydra.create_dataset(admin_description.last, "UUID HERE", ["/Users/martyn/Desktop/hello_world.txt"])


    else
      raise("Cannot find METS xml file in: #{dip_folder}")
    end
  end


  private

  def self.post_to_hydra(hydra_client)
    

  end

  def self.extract_admin_data(dip_folder, mets_xml, admin_filename)
    admin_struct = mets_xml.at_xpath("mets:mets/mets:structMap/mets:div[@TYPE='Directory']/mets:div[@LABEL='objects' and @TYPE='Directory']/mets:div[@LABEL='admin' and @TYPE='Directory']")

    file_uuid = admin_struct.at_xpath("mets:div[@LABEL='#{admin_filename}' and @TYPE='Item']/mets:fptr/@FILEID")
    unless file_uuid.present?
      raise "UUID not found for: #{admin_filename}"
    end

    filename = find_object_filename_by_uuid(dip_folder, file_uuid.value.sub("file-","")) # Dir.glob(File.join(dip_folder, "objects", file_uuid.value.sub("file-","") + "-" + admin_filename)).first
    unless File.exists?(filename)
      raise "File does not exist: #{filename}"
    end

    return File.open(filename) { |f| JSON.parse(f.read) }
  end

  def self.find_file_references(dip_folder, mets_xml, content_filename)
    content_struct = mets_xml.at_xpath("mets:mets/mets:structMap/mets:div[@TYPE='Directory']/mets:div[@LABEL='objects' and @TYPE='Directory']/mets:div[@LABEL='content' and @TYPE='Directory']")
    div = content_struct.at_xpath("mets:div[@LABEL='#{content_filename}']")

    if div.at_xpath("@TYPE").value == "Directory"
      div.xpath("mets:div").map {|x| build_file_reference(dip_folder, x.attribute("LABEL").value, x.at_xpath("mets:fptr/@FILEID"))}
    else
      [ build_file_reference(dip_folder, div.attribute("LABEL").value, div.at_xpath("mets:fptr/@FILEID")) ]
    end

  end

  def self.build_file_reference(dip_folder, label, file_uuid)
    if file_uuid.present?
      uuid = file_uuid.value.sub("file-","")
      [{label => {uuid: uuid,  filename: find_object_filename_by_uuid(dip_folder, uuid)}}]
    else
      nil
    end
  end


  def self.find_object_filename_by_uuid(dip_folder, uuid)
    if file_uuid.present?
      Dir.glob(File.join(dip_folder, "objects", uuid + "-*" )).first
    else
      nil
    end
  end


end