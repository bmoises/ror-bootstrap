require 'FileUtils'

class Klasser
  
  attr_accessor :output_directory, :file_name, :table_name, :class_name
  attr_accessor :belongs_to, :has_many, :has_and_belong_to_many
  def initialize
    @belongs_to = []
    @has_many = []
    @has_and_belong_to_many = []
  end
  
  def write_out!
    FileUtils.mkdir_p(directory_destination)
    File.open(destination,'w') do |file|
      file.puts "class #{class_name} < ActiveRecord::Base"
      @belongs_to.each do |bt|
        bt = bt.split("_").collect{|a| a.singular}.join("_")
        file.puts "  belongs_to :#{bt}"
      end
      
      @has_many.each do |hm|
        file.puts "  has_many :#{hm}"
      end
      
      @has_and_belong_to_many.each do |hbtm|
        file.puts "  has_and_belongs_to_many :#{hbtm}"
      end
      file.puts "end"
    end
  end
  
  def directory_destination
    File.dirname(destination)
  end
  def destination
    File.join(@output_directory,@file_name)
  end
end
