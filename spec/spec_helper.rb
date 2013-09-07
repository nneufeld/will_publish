require 'active_record'

# set adapter to use, default is sqlite3
# to use an alternative adapter run => rake spec DB='postgresql'
db_name = ENV['DB'] || 'sqlite3'
database_yml = File.expand_path('../db/database.yml', __FILE__)

if File.exists?(database_yml)
  active_record_configuration = YAML.load_file(database_yml)
  ActiveRecord::Base.configurations = active_record_configuration
  
  ActiveRecord::Base.establish_connection(db_name)
  ActiveRecord::Migration.verbose = false
    
  load(File.dirname(__FILE__) + '/db/schema.rb')
  load(File.dirname(__FILE__) + '/models.rb')
  
else
  raise "Please create #{database_yml} first to configure your database. Take a look at: #{database_yml}.sample"
end

RSpec.configure do |config|
  config.before(:each) do
    clean_database!
  end
end

def clean_database!
  models = [Guide, Step, Author, Comment]
  models.each do |model|
    ActiveRecord::Base.connection.execute "DELETE FROM #{model.table_name}"
  end
end

clean_database!