require 'date'
require 'logger'
require 'net/http'
require 'uri'
require 'yaml'

require 'pry'
require 'nokogiri'
require 'twitter'

require_relative 'atcoder-tl/ranking_page'
require_relative 'atcoder-tl/user_page'
require_relative 'atcoder-tl/util'
include Util

def colors
  color = Struct.new(:name, :rating_lb, :rating_ub, :last_competed_until)
  today = Date.today
  [
    color.new('test',   3000, 9999, today << 3),
#     color.new('red',    2800, 9999, today << 12),
#     color.new('orange', 2400, 2799, today << 6),
#     color.new('yellow', 2000, 2399, today << 6),
#     color.new('blue',   1600, 1999, today << 3),
#     color.new('cyan',   1200, 1599, today << 3),
#     color.new('green',   800, 1199, today << 3),
#     color.new('brown',   400,  799, today << 3),
#     color.new('gray',      0,  399, today << 3),
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

def main
  config = open('./config.yml', 'r') { |f| YAML.load(f) }
  twitter_client = get_twitter_client(config['twitter'])
  colors.each do |color|
    logger.info "[#{color.name}] Started processing"

    atcoder_usernames = RankingPage.usernames(color)
    log_ids('atcoder_usernames', atcoder_usernames, color)

    twitter_ids_new = UserPage.twitter_ids(atcoder_usernames, color)
    log_ids('twitter_ids_new', twitter_ids_new, color)

    list = twitter_client.lists.select{|list| list.name == "atcoder-tl-#{color.name}"}.first
    twitter_ids_current = twitter_client.list_members(list).
      map{|member| member.screen_name}
    log_ids('twitter_ids_current', twitter_ids_current, color)

    twitter_ids_to_be_added   = twitter_ids_new     - twitter_ids_current
    twitter_ids_to_be_removed = twitter_ids_current - twitter_ids_new
    log_ids('twitter_ids_to_be_added', twitter_ids_to_be_added, color)
    log_ids('twitter_ids_to_be_removed', twitter_ids_to_be_removed, color)

    twitter_ids_to_be_added.each_slice(100) do |ids|
      twitter_client.add_list_members(list, ids)
    end
    count_after_add = list.member_count

    twitter_ids_to_be_removed.each_slice(100) do |ids|
      twitter_client.remove_list_members(list, ids)
    end
    count_after_delete = list.member_count

    add_count    = count_after_add - twitter_ids_current.size
    delete_count = count_after_delete - count_after_add

    tweet = "atcoder-tl-#{color.name} を更新しました。\n"
    tweet << "#{add_count}名が追加され、#{delete_count}名が削除されました。\n"
    tweet << "https://twitter.com/atcoder_tl/lists/atcoder-tl-#{color.name}"
    logger.info "[#{color.name}] #{tweet}"
    twitter_client.update(tweet)

    logger.info "[#{color.name}] Finished processing"
  end
end

if $0 == __FILE__
  main
end
