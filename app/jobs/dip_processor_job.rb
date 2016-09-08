require 'nokogiri'
require 'dip_reader'
require 'hydra_client'

class DIPProcessorJob
  @queue = :dip_processor

  # example
  #dip_folder='/Users/martyn/Desktop/DIP/test_package_4_A.Ranganathan_2016-09-03T04_26_09-07_00-53f798ca-4076-4d77-92bd-0f15e0f6a11e'

  def self.perform(dip_folder)

    @dip = DIPReader.new(dip_folder)
    @hydra = HydraClient.new


    @dip.descriptions.each do |description|
      puts "\nCreating dataset for: "
      puts description

      @hydra.create_dataset(description)

    end
  end

end