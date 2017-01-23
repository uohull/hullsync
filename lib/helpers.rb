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
    # Hydra object structure - single, multiple, metadata only. Default is metadata only
    # content model (Dataset) & pid root?

  description_txt, description_csv, object_structure, content_model = parse_descriptions(bagit_content_dir)

  if description_txt.nil?
    return false
  else
    metadata[:object_structure] = object_structure
    metadata[:content_model] = content_model

    create_admin_file(bagit_admin_dir, 'admin_metadata.json', metadata)

    if description_csv.any?
      create_admin_file(bagit_admin_dir, 'description.json', description_csv)
    else
      create_admin_file(bagit_admin_dir, 'description.json', description_txt)
    end
    return true
  end

end


def parse_descriptions(content_folder)
  # DC terms, citation, visibleFiles
  description_txt = {}
  description_txt_file = File.join(content_folder, 'DESCRIPTION.txt')
  description_txt_file = File.join(content_folder, 'DESCRIPTION.TXT') unless File.exists?(description_txt_file)

  if File.exist?(description_txt_file)
    File.open(description_txt_file, 'r') do |f|
      f.each_line do |line|
        if line
          line = line.strip
        end
        next unless line.length > 0
        next if line.start_with?('#')
        key, val = line.split(':', 2)
        val = sanitize_value(key, val)
        if val
          description_txt[key.to_sym] = val
        end
      end
    end

    description_txt[:contentModel] = parse_content_model(description_txt[:contentModel])
    description_txt[:filename] = parse_filename(content_folder, description_txt[:filename])
    description_txt[:visibleFiles] = parse_visible_files(content_folder, description_txt[:filename], description_txt[:visibleFiles])
  else
    print "ERROR: file not found: #{description_txt_file}"
    return nil, nil, nil, nil
  end

  description_csv_file = File.join(content_folder, 'DESCRIPTION.csv')
  description_csv_file = File.join(content_folder, 'DESCRIPTION.CSV') unless File.exists?(description_csv_file)
  description_csv = []
  if File.exist?(description_csv_file)
    csv_text = File.read(description_csv_file)
    csv = CSV.parse(csv_text, :headers => true)
    csv.each do |row|
      description_csv_row = {}
      row.to_hash.each do |key, val|
        val = sanitize_value(key, val)
        if val
          description_csv_row[key.to_sym] = val
        end
      end

      # use description.txt to fill in blanks on description.csv
      description_txt.each do |key, val|
        if (not description_csv_row.has_key?(key)) or description_csv_row[key].nil? or description_csv_row[key].empty?
          description_csv_row[key] = val
        end
      end

      description_csv_row[:contentModel] = parse_content_model(description_csv_row[:contentModel])
      description_csv_row[:filename] = parse_filename(content_folder, description_csv_row[:filename])
      description_csv_row[:visibleFiles] = parse_visible_files(content_folder, description_csv_row[:filename], description_csv_row[:visibleFiles])

      description_csv.append(description_csv_row)
    end
  end

  # if there are multiple items in description.csv, the object_structure is multiple
  # if there are multiple items in description.txt.visibleFiles, the object_structure is multiple
  # if there is one item in description.csv, the object_structure is single
  # if there is one item in description.txt.visibleFiles, the object_structure is single
  # otherwise, the object_structure is metadata

  if description_csv.length > 1
    object_structure = 'multiple'
    content_model = description_txt[:contentModel]

  elsif description_txt[:visibleFiles].length > 1
    object_structure = 'multiple'
    content_model = description_txt[:contentModel]

  elsif description_csv.length == 1
    object_structure = 'single'
    content_model = description_csv.first[:contentModel]

  elsif description_txt[:visibleFiles].length == 1
    object_structure = 'single'
    content_model = description_txt[:contentModel]

  else
    object_structure = 'metadata'
    content_model = description_txt[:contentModel]
  end

  # ensure determined object_structure and contentModel are applied uniformly to both descriptions
  description_txt[:object_structure] = object_structure
  description_txt[:contentModel] = content_model

  description_csv.each do |description_csv_row|
    description_csv_row[:object_structure] = object_structure
    description_csv_row[:contentModel] = content_model
  end

  return description_txt, description_csv, object_structure, content_model
end

def parse_content_model(contentModel)
  supported_models = ['journal_article', 'book', 'image', 'dataset']
  if contentModel.present? && supported_models.include?(contentModel)
    contentModel
  else
    'dataset'
  end
end

def parse_filename(content_folder, filename)
  if filename.present? && File.exists?(File.join(content_folder, filename))
    filename
  else
    'all'
  end
end

def parse_visible_files(content_folder, filename, visible_files)
  parsed_visible_files = []

  if File.directory?(File.join(content_folder, filename))
    basedir = File.join(content_folder, filename)
  else
    basedir = content_folder
  end

  if !visible_files.nil?
    if visible_files.instance_of?(Array)
      visible_files.each do |visible_files_filename|
        if visible_files_filename == 'all'
          parsed_visible_files = Dir.entries(basedir).select {|f| !File.directory?(f) && f !~ /^description\.(txt|csv)$/i}
          break
        elsif File.exists?(File.join(basedir, visible_files_filename))
          parsed_visible_files.append(visible_files_filename)
        end
      end
    else
      if visible_files.instance_of?(String)
        if visible_files == 'all'
          parsed_visible_files = Dir.entries(basedir).select {|f| !File.directory?(f) && f !~ /^description\.(txt|csv)$/i}
        elsif File.exists?(File.join(basedir, visible_files))
          parsed_visible_files.append(visible_files)
        end
      end
    end
  end

  return parsed_visible_files
end

def create_admin_file(bagit_admin_dir, filename, data)
  content = JSON.pretty_generate(data)
  unless File.directory?(bagit_admin_dir)
    FileUtils.mkdir_p(bagit_admin_dir)
  end
  File.write(File.join(bagit_admin_dir, filename), content)
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
