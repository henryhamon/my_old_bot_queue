require 'active_record'

  class Network < ActiveRecord::Base

    has_many :tracked_networks

    validates_presence_of :name
    validates_presence_of :classification

    attr_accessible :name, :classification
  end

  class Brand < ActiveRecord::Base
    has_many :tracked_networks
    has_many :mining_terms
    has_many :sieves
    has_one  :occurrence_memory
    has_one  :theme_memory
    belongs_to :owner, :class_name => "User"
  end

  class TrackedNetwork < ActiveRecord::Base
    belongs_to :brand
    belongs_to :network
    has_many :limbos, :dependent => :destroy

    named_scope :all_passive, lambda {|*args| { :conditions => ["brand_id is not null AND tracked_networks.state = ?
      AND networks.classification = ?", "passive", (args.first || nil)],
      :order => "tracked_networks.updated_at ASC", :limit => 30, :include => :network}}

    named_scope :not_locked, lambda {|*args| { :conditions => ["brand_id is not null AND tracked_networks.state = ?
      AND networks.classification = ? AND tracked_networks.id not in (?)", "passive", (args[0] || nil), (args[1] || nil)],
      :order => "tracked_networks.updated_at ASC", :limit => 30, :include => :network}}

      named_scope :especific_brand, lambda {|*args| { :conditions => ["brand_id = ? AND tracked_networks.state = ?
      AND networks.classification = ?", (args[0] || nil), "passive", (args[1] || nil)],
      :order => "tracked_networks.updated_at ASC", :limit => 30, :include => :network}}

      named_scope :especific_track, lambda {|*args| { :conditions => ["brand_id is not null AND id = ?
      AND networks.classification = ?", (args[0] || nil), (args[1] || nil)],
      :order => "tracked_networks.updated_at ASC", :limit => 30, :include => :network}}

      def processing!
        self.state = 'in_processing' if self.state == 'passive'
        self.save
      end

      def processing?
        self.state == 'in_processing'
      end

      def mining_is_ok!
        self.state = 'passive' if self.state == 'in_processing'
        self.save
      end

      def passive?
        self.state == 'passive'
      end

      def mining_is_not_ok!
        self.state = 'registred' if self.state == 'in_processing'
        self.save
      end

  end


  class MiningTerm < ActiveRecord::Base
    belongs_to :brand

    def search_terms
      self.term.split(/,|;/)
    end

    def exclude_terms
      exclude_list = []
      self.filter.split(/,|;/).each do |filters|
        filters.strip!
        exclude_list << filters.gsub(/^-/,'') if filters.match(/^-/)
      end unless self.filter.nil?
      exclude_list
    end

    def filter_terms
      list = []
      self.filter.split(/,|;/).each do |filters|
        filters.strip!
        list << filters unless filters.match(/^-/)
      end unless self.filter.nil?
      list
    end


  end

