require 'byebug'

require 'active_record'
require File.expand_path('../../lib/will_publish', __FILE__)

# set adapter to use, default is sqlite3
# to use an alternative adapter run => rake spec DB='postgresql'
db_name = (ENV['DB'] || 'sqlite3').to_sym
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
  config.filter_run :focus => true
  config.run_all_when_everything_filtered = true

  config.before(:each) do
    clean_database!
  end
end

def clean_database!
  models = [Guide, Step, Author, Comment, WillPublish::PublishableMapping]
  models.each do |model|
    ActiveRecord::Base.connection.execute "DELETE FROM #{model.table_name}"
  end
end