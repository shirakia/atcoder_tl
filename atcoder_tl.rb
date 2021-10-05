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

def get_twitter_client(twitter_config)
  Twitter::REST::Client.new do |config|
    config.consumer_key        = twitter_config['consumer_key']
    config.consumer_secret     = twitter_config['consumer_secret']
    config.access_token        = twitter_config['access_token']
    config.access_token_secret = twitter_config['access_token_secret']
  end
end

def log_ids(name, ids, color)
  $logger.info "[#{color.name}] #{name}(#{ids.size}): #{ids.sort.join(', ')}"
end

def update_all(config)
  is_dry_run = false
  twitter_client = get_twitter_client(config['twitter'])
  twitter_client.update('全リストの更新を開始します。') unless is_dry_run

  all_and_agc_colors.each do |color|
    $logger.info "[#{color.name}] Started All Update"

    atcoder_usernames = RankingPage.usernames(color)
    log_ids('atcoder_usernames', atcoder_usernames, color)

    users = UserPage.users(atcoder_usernames, color)
    tids_new = users.select{ |k, v| v && v[:last_competed] >= color.last_competed_until }.
                        map{ |k, v| v[:tid] }.compact
    log_ids('tids_new', tids_new, color)

    list = twitter_client.owned_lists.select{|list| list.name == "atcoder_tl_#{color.name}"}.first
    tids_current = twitter_client.list_members(list).
      map{|member| member.screen_name.downcase}
    log_ids('tids_current', tids_current, color)

    tids_to_be_added   = tids_new     - tids_current
    tids_to_be_removed = tids_current - tids_new
    log_ids('tids_to_be_added', tids_to_be_added, color)
    log_ids('tids_to_be_removed', tids_to_be_removed, color)

    tids_to_be_added.each_slice(100) do |ids|
      twitter_client.add_list_members(list, ids) unless is_dry_run
    end
    count_after_add = twitter_client.list_members(list).count

    tids_to_be_removed.each_slice(100) do |ids|
      twitter_client.remove_list_members(list, ids) unless is_dry_run
    end
    count_after_delete = twitter_client.list_members(list).count

    add_count    = count_after_add - tids_current.size
    delete_count = count_after_add - count_after_delete

    $logger.info "[#{color.name}] atcoder_tl_#{color.name} を更新。#{add_count}名を追加、#{delete_count}名を削除。"
    $logger.info "[#{color.name}] List URL: " + list.url.to_s
    $logger.info "[#{color.name}] Finished processing"

    File.open("./data/#{color.name}.json", 'w') do |file|
      JSON.dump(users, file)
    end
  end

  twitter_client.update('全リストの更新を完了しました。') unless is_dry_run
end

if $0 == __FILE__
  config = open('./config.yml.bot', 'r') { |f| YAML.load(f) }
  # $logger = Logger.new("./log/all_#{Date.today.strftime('%y%m%d')}.log")
  $logger = Logger.new(STDOUT)

  update_all(config)
end
