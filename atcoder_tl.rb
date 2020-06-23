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
require_relative 'atcoder_tl/standings_page'
require_relative 'atcoder_tl/util'
include Util

def colors
  color = Struct.new(:name, :name_ja, :rating_lb, :rating_ub, :last_competed_until, :url)
  today = Date.today
  # TODO configに出す
  [
    # color.new('test',   'テ', 3000, 9999, today << 3,  'https://twitter.com/i/lists/1265295344977408000'),
    # color.new('red',    '赤', 2800, 9999, today << 12, 'https://twitter.com/i/lists/1265268852528566273'),
    # color.new('orange', '橙', 2400, 2799, today << 6,  'https://twitter.com/i/lists/1265268943393943554'),
    # color.new('yellow', '黄', 2000, 2399, today << 6,  'https://twitter.com/i/lists/1265269023278690304'),
    # color.new('blue',   '青', 1600, 1999, today << 3,  'https://twitter.com/i/lists/1265269077888479235'),
    # color.new('cyan',   '水', 1200, 1599, today << 3,  'https://twitter.com/i/lists/1265269135493099526'),
    # color.new('green',  '緑',  800, 1199, today << 3,  'https://twitter.com/i/lists/1265269191877124101'),
    # color.new('brown',  '茶',  400,  799, today << 3,  'https://twitter.com/i/lists/1265269251641761793'),
    # color.new('gray',   '灰',    1,  399, today << 3,  'https://twitter.com/i/lists/1265269317169340417'),
  ]
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
  logger.info "[#{color.name}] #{name}(#{ids.size}): #{ids.sort.join(', ')}"
end

def update_all(config)
  twitter_client = get_twitter_client(config['twitter'])

  colors.each do |color|
    logger.info "[#{color.name}] Started All Update"

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
      twitter_client.add_list_members(list, ids)
    end
    count_after_add = twitter_client.list_members(list).count

    tids_to_be_removed.each_slice(100) do |ids|
      twitter_client.remove_list_members(list, ids)
    end
    count_after_delete = twitter_client.list_members(list).count

    add_count    = count_after_add - tids_current.size
    delete_count = count_after_add - count_after_delete

    tweet = "atcoder_tl_#{color.name} を更新しました。\n"
    tweet << "#{add_count}名が追加され、#{delete_count}名が削除されました。\n"
    tweet << color.url
    logger.info "[#{color.name}] #{tweet}"

    logger.info "[#{color.name}] List URL: " + list.url.to_s
    logger.info "[#{color.name}] Finished processing"

    File.open("./data/#{color.name}.json", 'w') do |file|
      JSON.dump(users, file)
    end
  end
end

def update_after_contest(config)
  is_dry_run = false
  twitter_client = get_twitter_client(config['twitter'])
  standings = StandingsPage.new('tokiomarine2020')
  name2tid = {}
  %w[red orange yellow blue cyan green brown gray].each{|c| name2tid.merge! JSON.parse(File.read("./data/#{c}.json"))}

  colors.each do |color|
    logger.info "[#{color.name}] Started After Contest Update"
    users_to_be_added = standings.users_to_be_added(color)

    tids_to_be_added = users_to_be_added
                         .map{ |user| name2tid[user['UserScreenName']]&.fetch('tid') }.compact
    log_ids('tids_to_be_added', tids_to_be_added, color)

    users_to_be_removed = standings.users_to_be_removed(color)
    tids_to_be_removed = users_to_be_removed
                           .map{ |user| name2tid[user['UserScreenName']]&.fetch('tid') }.compact
    log_ids('tids_to_be_removed', tids_to_be_removed, color)

    list = twitter_client.owned_lists.select{|list| list.name == "atcoder_tl_#{color.name}"}.first
    tids_to_be_added.each_slice(100) do |ids|
      twitter_client.add_list_members(list, ids) unless is_dry_run
    end
    tids_to_be_removed.each_slice(100) do |ids|
      twitter_client.remove_list_members(list, ids) unless is_dry_run
    end

    users_comming_up = standings.users_comming_up(color)
    users_going_down = standings.users_going_down(color)
    tweet = "atcoder_tl_#{color.name} を更新しました。\n"
    tweet << "#{users_comming_up.size}名が#{color.name_ja}TL未満から#{color.name_ja}TLに追加されました。\n"
    tweet << "#{users_going_down.size}名が#{color.name_ja}TLから#{color.name_ja}TL未満に移動されました。\n"
    tweet << color.url
    logger.info "[#{color.name}] #{tweet}"
    twitter_client.update(tweet) unless is_dry_run

    sleep(5)
    logger.info "[#{color.name}] Finished processing"
  end
end

if $0 == __FILE__
  config = open('./config.yml', 'r') { |f| YAML.load(f) }
  update_after_contest(config)
  # update_all(config)
end
