require 'rubygems'
require 'spec'

require File.expand_path(File.dirname(__FILE__) + '/../lib/kraken.rb')
require File.expand_path(File.dirname(__FILE__) + '/../lib/master_database.rb')

describe Kraken do

  before(:each) do
    Search.delete_all
    BotQueue.delete_all
    @kraken = Kraken.new
  end

  it "should load all the bot park" do
    @kraken.bot_park.should == {"followers"=>1, "online_media"=>1, "artificial_inteligence"=>2, "facebook"=>1, "viral_network"=>1, "twitter"=>3} 
  end

  it "need to get the first search" do
    Search.create(:next_time => DateTime.now + 3.minutes, :mining_term_id => 3553, :bot_type => 'twitter')
    Search.create(:next_time => DateTime.now + 4.minutes, :mining_term_id => 3554, :bot_type => 'twitter')
    search = Search.create(:next_time => DateTime.now - 5.minutes, :mining_term_id => 3555, :bot_type => 'twitter')

    @kraken.start_all

    @kraken.searchs.first.should == search
  end

  it "need to get search when next_time is null" do
    Search.create(:next_time => DateTime.now + 3.minutes, :mining_term_id => 3553, :bot_type => 'twitter')
    Search.create(:next_time => DateTime.now + 4.minutes, :mining_term_id => 3554, :bot_type => 'twitter')
    Search.create(:next_time => DateTime.now - 5.minutes, :mining_term_id => 3555, :bot_type => 'twitter')
    search = Search.create( :mining_term_id => 3552, :bot_type => 'twitter')

    @kraken.start_all

    @kraken.searchs.last.should == search
  end

  it "can't schedule a search then exist in a queue" do
    search = Search.create(:next_time => DateTime.now - 3.minutes, :mining_term_id => 3553, :bot_type => 'twitter')
    aux = Search.create(:next_time => DateTime.now - 4.minutes, :mining_term_id => 3554, :bot_type => 'twitter')
    BotQueue.create(:search_id => aux.id, :bot_type => 'twitter')
    aux = Search.create(:next_time => DateTime.now - 5.minutes, :mining_term_id => 3555, :bot_type => 'twitter')
    BotQueue.create(:search_id => aux.id, :bot_type => 'twitter')

    @kraken.start_all
    @kraken.bqueue.search_id.should == search.id

  end

  it "need to guarantee mining frequence and balance" do

  end


end
