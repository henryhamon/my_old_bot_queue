require "yaml"
require 'active_record'

root = File.join(File.expand_path(File.dirname(__FILE__)),"..")
database_config = YAML::load(File.open("#{root}/config/database.yml"))

ActiveRecord::Base.establish_connection( database_config['master'] )

class Account < ActiveRecord::Base
  belongs_to :owner, :class_name => "User"
  belongs_to :plan
  has_one :utilization_plan, :dependent => :destroy
end

class BotQueue < ActiveRecord::Base
  belongs_to :brand
  belongs_to :network
  has_one :search

  named_scope :search_verification, lambda {|*args| {
    :conditions => ["bot_type = ? AND state in ('in_processing', 'passive') AND search_id = ?", (args[0] || nil), (args[1] || nil) ]
  }}

  named_scope :search_by_brand, lambda {|*args| {
    :conditions => ["bot_type = ? AND state in ('in_processing', 'passive') AND brand_id = ?", (args[0] || nil), (args[1] || nil) ]
  }}

  named_scope :by_work_class, lambda {|*args| {
    :conditions => ["work_class = ? AND bot_type = ? AND state = 'passive' ", (args[0] || nil), (args[1] || nil) ],
    :order => 'created_at ASC',
    :limit => 1
  }}

  def processing!
    self.state = 'in_processing' if self.state == 'passive'
    self.save
  end

  def processing?
    self.state == 'in_processing'
  end

  def finishing!
    self.state = 'finished' if self.state == 'in_processing'
    self.save
  end

  def finished?
    self.state == 'finished'
  end

  def passive?
    self.state == 'passive'
  end

  def problem!
    self.state = 'passive'
    self.save
  end

end

class Search < ActiveRecord::Base
  belongs_to :mining_term

  named_scope :last_job_by_bot_type, lambda {|*args| {
    :conditions => ["state = 'passive' AND bot_type = ? AND next_time < ? AND (deleted_at is null)",  (args.first || nil), (DateTime.now + 1.minute).strftime('%Y-%m-%d %H:%M')],
    :order => "next_time ASC",
    :limit => 500
    }
  }

end

