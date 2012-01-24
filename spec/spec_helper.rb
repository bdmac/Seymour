$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "..", "lib"))

MODELS = File.join(File.dirname(__FILE__), "models")
$LOAD_PATH.unshift(MODELS)

require 'seymour'
require 'mongoid'
require 'rspec'

Seymour.configure do |config|
  config.distribution = :immediate
  config.base_activity_class = 'Activities::Activity'
end

LOGGER = Logger.new($stdout)
DATABASE_ID = Process.pid

Mongoid.configure do |config|
  database = Mongo::Connection.new.db("mongoid_#{DATABASE_ID}")
  database.add_user("mongoid", "test")
  config.master = database
  config.logger = nil
end

Dir[File.expand_path(File.join(File.dirname(__FILE__),'models','**','*.rb'))].each {|f| require f}

RSpec.configure do |config|
  config.include RSpec::Matchers
  config.include Mongoid::Matchers
  config.mock_with :rspec
  
  config.before(:each) do
    Mongoid::IdentityMap.clear
  end
  
  config.after :suite do
    Mongoid.master.connection.drop_database("mongoid_#{DATABASE_ID}")
  end
end