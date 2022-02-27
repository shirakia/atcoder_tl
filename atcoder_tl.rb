require 'date'
require 'json'
require 'logger'
require 'net/http'
require 'uri'
require 'yaml'

require 'pry'
require 'nokogiri'
require 'twitter'

require_relative 'atcoder_tl/ranking_page'
require_relative 'atcoder_tl/user_page'

def colors
  color = Struct.new(:name, :name_ja, :rating_lb, :rating_ub, :last_competed_until, :url)
  today = Date.today
  # TODO configに出す
  [
    # color.new('test',   'テ', 3000, 9999, today << 3,  'https://twitter.com/i/lists/1265295344977408000'),
    color.new('red',    '赤', 2800, 9999, today << 12, 'https://twitter.com/i/lists/1265268852528566273'),
    color.new('orange', '橙', 2400, 2799, today << 6,  'https://twitter.com/i/lists/1265268943393943554'),
    color.new('yellow', '黄', 2000, 2399, today << 6,  'https://twitter.com/i/lists/1265269023278690304'),
    color.new('blue',   '青', 1600, 1999, today << 3,  'https://twitter.com/i/lists/1265269077888479235'),
    color.new('cyan',   '水', 1200, 1599, today << 3,  'https://twitter.com/i/lists/1265269135493099526'),
    color.new('green',  '緑',  800, 1199, today << 3,  'https://twitter.com/i/lists/1265269191877124101'),
    color.new('brown',  '茶',  400,  799, today << 3,  'https://twitter.com/i/lists/1265269251641761793'),
    color.new('gray',   '灰',    1,  399, today << 3,  'https://twitter.com/i/lists/1265269317169340417'),
  ]
end

def all_and_agc_colors
  if colors.size <= 4
    colors
  else
    colors + colors.slice(0, 4)
  end
end

class AtCoderTL
  def initialize(config, is_dry_run)
    @config = config
    @is_dry_run = is_dry_run
    @twitter_client = Twitter::REST::Client.new do |config|
      config.consumer_key        = @config['twitter']['consumer_key']
      config.consumer_secret     = @config['twitter']['consumer_secret']
      config.access_token        = @config['twitter']['access_token']
      config.access_token_secret = @config['twitter']['access_token_secret']
    end
  end

  def log_ids(name, ids, color)
    $logger.info "[#{color.name}] #{name}(#{ids.size}): #{ids.sort.join(', ')}"
  end

  def tweet(text)
    @twitter_client.update(text) unless @is_dry_run
  end

  def update_all
    atcoder_users_all = RankingPage.users()

    $logger.info "atcoder_users_all count: #{atcoder_users_all.size}"
    if atcoder_users_all.empty?
      $logger.info 'リストの更新に失敗しました。'
      tweet('リストの更新に失敗しました。')
      return
    end

    tweet('全リストの更新を開始します。')

    all_and_agc_colors.each do |color|
      $logger.info "[#{color.name}] Started All Update"

      atcoder_usernames = atcoder_users_all.select do |user|
        user.rating.between?(color.rating_lb, color.rating_ub)
      end.map(&:username)

      log_ids('atcoder_usernames', atcoder_usernames, color)

      users = UserPage.users(atcoder_usernames, color)
      tids_new = users.select{ |k, v| v && v[:last_competed] >= color.last_competed_until }.
                          map{ |k, v| v[:tid] }.compact
      log_ids('tids_new', tids_new, color)

      list = @twitter_client.owned_lists.select{|list| list.name == "atcoder_tl_#{color.name}"}.first
      tids_current = @twitter_client.list_members(list).map{|member| member.screen_name.downcase}
      log_ids('tids_current', tids_current, color)

      tids_to_be_added   = tids_new     - tids_current
      tids_to_be_removed = tids_current - tids_new
      log_ids('tids_to_be_added', tids_to_be_added, color)
      log_ids('tids_to_be_removed', tids_to_be_removed, color)

      @twitter_client.add_list_members(list, tids_to_be_added) unless @is_dry_run
      count_after_added = @twitter_client.list_members(list).count

      @twitter_client.remove_list_members(list, tids_to_be_removed) unless @is_dry_run
      count_after_deleted = @twitter_client.list_members(list).count

      added_count   = count_after_added - tids_current.size
      deleted_count = count_after_added - count_after_deleted

      $logger.info "[#{color.name}] atcoder_tl_#{color.name} を更新。#{added_count}名を追加、#{deleted_count}名を削除。"
      $logger.info "[#{color.name}] List URL: " + list.url.to_s
      $logger.info "[#{color.name}] Finished processing"

      File.open("./data/#{color.name}.json", 'w') do |file|
        JSON.dump(users, file)
      end
    end

    tweet('全リストの更新を完了しました。')
  end
end

if $0 == __FILE__
  config = open('./config.yml.bot', 'r') { |f| YAML.load(f) }
  # $logger = Logger.new("./log/all_#{Date.today.strftime('%y%m%d')}.log")
  $logger = Logger.new(STDOUT)
  atl = AtCoderTL.new(config, true)
  atl.update_all
end
