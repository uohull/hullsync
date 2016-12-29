require 'fileutils'
require 'csv'
require 'json'

DC_TERMS = %w(abstract accessRights accrualMethod accrualPeriodicity accrualPolicy alternative audience available
bibliographicCitation conformsTo contributor coverage created creator date dateAccepted dateCopyrighted dateSubmitted
description educationLevel extent format hasFormat hasPart hasVersion identifier instructionalMethod isFormatOf isPartOf
isReferencedBy isReplacedBy isRequiredBy issued isVersionOf language license mediator medium modified provenance publisher
references relation replaces requires rights rightsHolder source spatial subject tableOfContents temporal title type valid)

MULTI_FIELDS = %w(creator visibleFiles)

OTHER_TERMS = %w(filename citation visibleFiles)

def copy_folder(source, destination)
  return false unless File.directory?(source)
  if File.directory?(destination)
    FileUtils.rm_rf(destination)
  end
  FileUtils.mkdir_p(destination)
  FileUtils.cp_r File.join(source, '.'), destination, :verbose => false
  true
end

def create_bagit_metadata_files(bagit_content_dir, bagit_admin_dir, metadata)
  # Admin Metadata contents
    # depositor_name
    # depositor_email
    # date_created
    # ingest_route
    # original_name (of file or dir)
    # Rights statement - default?
    # Hydra object structure - single, multiple, metadata only. Default is single metadata only
    # content model (Dataset) & pid root?
  metadata[:object_structure] = 'metadata'
  metadata[:content_model] = 'dataset'
  description = parse_description(bagit_content_dir)
  if description.is_a?(Hash)
    if description.has_key?(:objectStructure)
      metadata[:object_structure] = description[:objectStructure]
    end
    if description.has_key?(:content_model)
      metadata[:content_model] = description[:content_model]
    end
  elsif description.is_a?(Array) and description.length == 1
    if description[0].has_key?(:objectStructure)
      metadata[:object_structure] = description[0][:objectStructure]
    end
    if description[0].has_key?(:content_model)
      metadata[:content_model] = description[0][:content_model]
    end
  elsif description.is_a?(Array) and description.length > 1 and description.all?
    metadata[:object_structure] = 'multiple'
    if description[0].has_key?(:content_model)
      metadata[:content_model] = description[0][:content_model]
    end
  end
  create_admin_file(bagit_admin_dir, 'description.json', description)
  create_admin_file(bagit_admin_dir, 'admin_metadata.json', metadata)
end

def create_admin_file(bagit_admin_dir, filename, data)
  content = JSON.pretty_generate(data)
  unless File.directory?(bagit_admin_dir)
    FileUtils.mkdir_p(bagit_admin_dir)
  end
  File.write(File.join(bagit_admin_dir, filename), content)
end

def parse_description(content_folder)
  metadata_txt = description_txt_to_hash(content_folder)
  metadata_csv = description_csv_to_hash(content_folder)
  if metadata_txt.any? and metadata_csv.any?
    metadata_txt.each do |key, val|
      metadata_csv.each do |metadata|
        if not metadata.has_key?(key) or metadata[key].nil? or metadata[key].empty?
          metadata[key] = val
        end
      end
    end
    metadata_csv
  else
    metadata_txt
  end
end

def description_txt_to_hash(content_folder)
  # DC terms, citation, visibleFiles
  description_file = File.join(content_folder, 'DESCRIPTION.txt')
  return {} unless File.exist?(description_file)
  metadata = {}
  File.open(description_file, 'r') do |f|
    f.each_line do |line|
      if line
        line = line.strip
      end
      next unless line.length > 0
      next if line.start_with?('#')
      key, val = line.split(':', 2)
      val = sanitize_value(key, val)
      if val
        metadata[key.to_sym] = val
      end
    end
  end
  if metadata.any?
    metadata[:filename] = 'all'
    files_exist, structure = object_structure(metadata, content_folder)
    metadata[:objectStructure] = structure
    # TODO overwriting visibleFiles with visibleFiles that exist. Need to raise error if not all files exist
    metadata[:visibleFiles] = files_exist
    metadata[:content_model] = content_model(metadata)
  end
  metadata
end

def description_csv_to_hash(content_folder)
  description_file = File.join(content_folder, 'DESCRIPTION.csv')
  return {} unless File.exist?(description_file)
  metadata = []
  csv_text = File.read(description_file)
  csv = CSV.parse(csv_text, :headers => true)
  csv.each do |row|
    row_metadata = {}
    row.to_hash.each do |key, val|
      val = sanitize_value(key, val)
      if val
        row_metadata[key.to_sym] = val
      end
    end
    if row_metadata
      files_exist, structure = object_structure(row_metadata, content_folder)
      if structure
        row_metadata[:objectStructure] = structure
        # TODO overwriting visibleFiles with visibleFiles that exist. Need to raise error if not all files exist
        row_metadata[:visibleFiles] = files_exist
        metadata[:content_model] = content_model(row_metadata)
        metadata.append(row_metadata)
      end
    end
  end
  metadata
end

def sanitize_value(key, val)
  if key
    key = key.strip
  end
  if val
    val = val.strip
  end
  if DC_TERMS.include?(key) or OTHER_TERMS.include?(key)
    if MULTI_FIELDS.include?(key)
      if val.nil? or val.empty?
        val = []
      else
        val = val.split(';')
        val = val.map {|item| item.strip if item}
        val = val.reject { |item| item.nil? or item.empty? }
      end
    end
    val
  else
    nil
  end
end

def object_structure(metadata, content_folder)
  files_exist = []
  if metadata.has_key?(:filename) and (metadata[:filename] == 'all' or File.exists?(File.join(content_folder, metadata[:filename])))
    base_dir = content_folder
    if File.directory?(File.join(content_folder, metadata[:filename]))
      base_dir = File.join(content_folder, metadata[:filename])
    end
    if metadata.has_key?(:visibleFiles) and metadata[:visibleFiles].any?
      metadata[:visibleFiles].each do |filename|
        if filename == 'all'
          files_exist.append(filename)
        elsif File.exist?(File.join(base_dir, filename))
          files_exist.append(filename)
        end
      end
    end
    if files_exist.any?
      [files_exist, 'single']
    else
      [files_exist, 'metadata_only']
    end
  else
    [files_exist, nil]
  end
end

def content_model(metadata)
  supported_models = ['journal_article', 'book', 'image', 'dataset']
  if metadata.has_key?(:content_model) and supported_models.include?(metadata[:content_model].downcase)
    model = metadata[:content_model].downcase
  else
    model = 'dataset'
  end
  model
end
