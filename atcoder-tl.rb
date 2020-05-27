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

COLORS = {
  test: [3000, 9999],
#  red: [2800, 9999],
#   orange: [2400, 2799],
#   yellow: [2000, 2399],
#   blue: [1600, 1999],
#   cyan: [1200, 1599],
#   green: [800, 1199],
#   brown: [400, 799],
#   gray: [0, 399],
}

def get_twitter_client(twitter_config)
  Twitter::REST::Client.new do |config|
    config.consumer_key        = twitter_config['consumer_key']
    config.consumer_secret     = twitter_config['consumer_secret']
    config.access_token        = twitter_config['access_token']
    config.access_token_secret = twitter_config['access_token_secret']
  end
end

def log_ids(name, ids)
  logger.info "#{name}(#{ids.size}): #{ids.join(', ')}"
end

def main
  config = open('./config.yml', 'r') { |f| YAML.load(f) }
  twitter_client = get_twitter_client(config['twitter'])

  COLORS.each do |color, rating|
    logger.info "Start processing #{color}"
    atcoder_usernames = RankingPage.usernames(rating)
    log_ids('atcoder_usernames', atcoder_usernames)

    twitter_ids_new = UserPage.twitter_ids(atcoder_usernames)
    log_ids('twitter_ids_new', twitter_ids_new)

    list = twitter_client.lists.select{|list| list.name == "atcoder-tl-#{color}"}.first
    twitter_ids_current = twitter_client.list_members(list).map{|member| member.screen_name}
    log_ids('twitter_ids_current', twitter_ids_current)

    twitter_ids_to_be_added   = twitter_ids_new     - twitter_ids_current
    twitter_ids_to_be_removed = twitter_ids_current - twitter_ids_new
    log_ids('twitter_ids_to_be_added', twitter_ids_to_be_added)
    log_ids('twitter_ids_to_be_removed', twitter_ids_to_be_removed)

    twitter_ids_to_be_added.each_slice(100) do |ids|
      twitter_client.add_list_members(list, ids)
    end

    twitter_ids_to_be_removed.each_slice(100) do |ids|
      twitter_client.remove_list_members(list, ids)
    end

    logger.info "Finished processing #{color}"
  end
end

main
