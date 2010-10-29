require 'rubygems'

require 'mysql'

require 'inflection'
require 'klasser'
require 'permute'
require 'pp'

db = ARGV[0] || (raise 'Need to specify database')
output_dir = ARGV[1] || (raise 'Need to specify output dir')

my = Mysql::new("localhost", "root", "", db)

# First collect all table names
res = my.query("SHOW TABLES")
tables = []
res.each do |row|
  table_name = row[0]
  tables << row[0] if !(table_name =~ /^(schema_migration|schema_info)$/)
end

tables.sort!

# Collect columns for each table
data = {}
tables.each do |table|
  data[table] = []
  res = my.query("DESC #{table}")
  
  res.each do |row|
    column_name = row[0]
    data[table] << column_name if !( column_name =~ /^(id|created_at|updated_at)$/)
  end
end

klassers = []

data.each do |table,columns|
  class_name = table.split("_").collect{|a| a.singular.capitalize}.join("")
  table_name = table.split("_").collect{|a| a.singular}.join("_")
  puts table + " " + class_name
  
  klasser = Klasser.new
  klasser.output_directory = output_dir
  klasser.file_name = "#{table_name}.rb"
  klasser.table_name = table
  klasser.class_name = class_name
  
  columns.each do |column|
    if column =~ /_id$/
      klasser.belongs_to << column.gsub(/_id/,'')
      puts "  #{column} -- #{column.singular}"
    end
    
  end
  klassers << klasser
end


# :has_and_belongs_to_many
klassers.each do |klasser|
  klasser.table_name.permute.each do |left|

    right = klasser.table_name.gsub("#{left}_",'')
    # if it matches, that means that this is possible a has and belongs to many
    if klasser.belongs_to.include?(left.singular) && klasser.belongs_to.include?(right.singular)

      # We delete any instance in this class
      klasser.belongs_to.delete(left.singular)
      klasser.belongs_to.delete(right.singular)

      # We try and add the 'hbtm' relationship to respective classes
      elems = [left,right]
      elems.each do |elem|
        klassers.each do |kls|
          if kls.table_name == elem && !kls.has_and_belong_to_many.include?(elem)
            kls.has_and_belong_to_many << (elems - [elem]).first
          end
        end
      end
    end
  end
  
end


# now that we have all klassers, go ahead and determine what the :has_many relationships are
klassers.each do |klasser|
  klasser.belongs_to.each do |bt|
    klassers.each do |kls|
      if kls.table_name.singular == bt
        kls.has_many << klasser.table_name
      end
    end
  end
end



#write out files
klassers.each do |klasser|
  klasser.write_out!
end
