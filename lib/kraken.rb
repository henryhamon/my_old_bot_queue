require "rubygems"
require File.join(File.expand_path(File.dirname(__FILE__)), "master_database")
require File.join(File.expand_path(File.dirname(__FILE__)), "slave_database")

class Kraken
  attr_accessor :logger, :bot_park, :process_brand
  attr_reader :searchs, :bqueue

  NETWORKS_TYPE = {}

  def initialize
    @logger = Hash.new
    config_path = File.join(File.expand_path(File.dirname(__FILE__)), "../config")
    settings = YAML::load(File.open("#{config_path}/settings.yml")) rescue Hash.new
    @bot_park = settings["bot_park"]
    @park_schedules = last_schedules
    @searchs = nil
    @bqueue = nil
  end

  def start_all
    self.process
  end

  protected

  def process

    # agenda para cada tipo de rede
    NETWORKS_TYPE.each_key do |bot_type|

      # Realiza o processo de acordo cm a qtd de bots existente
      @bot_park[bot_type].times do

        # Pega todos as searchs que next_time é menor que a Data e Hora atual
        # que deleted_at seja nulo
        # e que o state seja passive
        @searchs = Search.last_job_by_bot_type bot_type

        flag = false
        @searchs.each do |search|

          # Loop em todas as searchs até efetuar um agendamento
          unless flag

            @account = Account.find search.account_id
            bqueue = BotQueue.search_verification(bot_type, search.id)

            # só irá agendar caso:
            # 1 - Account não for nulo
            # 2 - Não exista agendamento para esta search
            # 3 - Consiga se conectar ao banco client
            if !@account.nil? && bqueue.size == 0 && load_shard(search)

              # Ignora a search caso acontecer erro
              # ou se não encontrar mining_term e brand
              begin
                mining_term = MiningTerm.find(search.mining_term_id)
                brand = Brand.find(mining_term.brand_id)
                work_class = @account.work_class rescue work_class = 'C'

                @bqueue = BotQueue.create(
                  :work_class => work_class,
                  :search_term => mining_term.term,
                  :filter_term => mining_term.filter_terms.join(','),
                  :filter_exclude_term => mining_term.exclude_terms.join(','),
                  :state => 'passive',
                  :bot_type => bot_type,
                  :network_id => NETWORKS_TYPE[bot_type],
                  :brand_id => mining_term.brand_id,
                  :language => brand.language,
                  :account_id => search.account_id,
                  :search_id => search.id
                )

                flag = true

                # Gera o agendamento auxiliar(AI e followers)
                aux = {:bot_type => bot_type, :work_class => work_class, :state => 'passive', :network_id => NETWORKS_TYPE[bot_type], :brand_id => mining_term.brand_id, :language => brand.language, :account_id => search.account_id, :search_id => search.id}
                self.auxiliary_queue(aux)
              rescue => ex
                puts ex.message
              end

              # Desconecta com client
              remove_shard
            end
          end
        end # search job
      end # bot park
    end # network type

  end

  # ---------------------
  def last_schedules
    output = Hash.new

    output
  end

  def internal_process

  end

  def auxiliary_queue(value)
    return if value[:bot_type] == 'online_press'

    aux = value.clone

    if value[:bot_type] == 'twitter'
      begin
        aux[:bot_type] = 'followers'
        bqueue = BotQueue.search_by_brand(aux[:bot_type], value[:brand_id])
        BotQueue.create(aux) if bqueue.size == 0
      rescue => ex
        puts ex.message
      end
    end # follower

    # artificial inteligence
    begin
      aux[:bot_type] = "artificial_intelligence_#{value[:bot_type]}"
      bqueue = BotQueue.search_by_brand(aux[:bot_type], value[:brand_id])
      BotQueue.create(aux) if bqueue.size == 0
    rescue => ex
      puts ex.message
    end
  end

  def load_shard(search)
    output = true
    begin
      shard = {:host => @account.host, :port => @account.port, :username => @account.username, :password => @account.password, :adapter => @account.adapter, :database => @account.database}
      Network.establish_connection shard
      Brand.establish_connection shard
      TrackedNetwork.establish_connection shard
      MiningTerm.establish_connection shard

    rescue => ex
      output = false
      log_here(ex.message)
      puts ex.message
    end

    output
  end

  def remove_shard
    Network.remove_connection
    Brand.remove_connection
    TrackedNetwork.remove_connection
    MiningTerm.remove_connection
  end



end

