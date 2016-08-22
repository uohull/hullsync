require 'fileutils'

def copy_folder(source, destination)
  puts 'in copy folder'
  return false unless File.directory?(source)
  if File.directory?(destination)
    puts 'Deleting existing destination dir'
    FileUtils.rm_rf(destination)
  else
    puts 'Destination dir does not exist'
  end
  puts 'Creating dir'
  FileUtils.mkdir_p(destination)
  puts 'copying file'
  FileUtils.cp_r File.join(source, '.'), destination, :verbose => false
  true
end

def create_metadata_files
  # TODO
end