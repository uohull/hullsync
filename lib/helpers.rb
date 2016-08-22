require 'fileutils'

def copy_folder(source, destination)
  return false unless File.directory?(source)
  if File.directory?(destination)
    FileUtils.rm_rf(destination)
  end
  FileUtils.mkdir_p(destination)
  FileUtils.cp_r File.join(source, '.'), destination, :verbose => false
  true
end

def create_bagit_metadata_files
  # TODO
end