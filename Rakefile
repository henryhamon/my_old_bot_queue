require 'rubygems'
require 'rake'

# task :default => :gem
# 
# task :gem do
  require 'echoe'
  Echoe.new('core', '0.0.7') do |s|
    s.description     = "Datamining Bot"
    s.url             = ""
    s.author          = "Henry Hamon"
    s.email           = ""
    s.ignore_pattern  = ["tmp/*", "script/*"]
    s.runtime_dependencies = ["json", "nokogiri", "mechanize", "activerecord"]
    s.development_dependencies = ["rspec"]
  end

  Dir["#{File.dirname(__FILE__)}/tasks/*.rake"].sort.each { |ext| load ext }
# end
# 
# desc "Migrate the database through scripts in db/migrate. Target specific version with VERSION=x"
# task :migrate => :environment do
  # ActiveRecord::Migrator.migrate('lib/skynet-core/db/migrate', ENV["VERSION"] ? ENV["VERSION"].to_i : nil )
# end
# 
# task :environment do
  # require 'active_record'
  # require 'yaml'
# 
  # database_config = YAML::load(File.open('config/database.yml'))
  # ActiveRecord::Base.establish_connection database_config[ENV["ENV"] ? ENV["ENV"] : "development"]["skynet"]
# end
# 
