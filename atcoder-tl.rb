require 'uri'
require 'net/http'
require "yaml"

require 'pry'
require 'nokogiri'
require 'twitter'

require_relative 'atcoder-tl/ranking_page'
require_relative 'atcoder-tl/user_page'

COLORS = {
  test: [3400, 9999],
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

def main(limit)
  config = open('./config.yml', 'r') { |f| YAML.load(f) }
  twitter_client = get_twitter_client(config['twitter'])

  COLORS.each do |color, rating|
    usernames = RankingPage.usernames(rating)
    p usernames
    p usernames.size
    twitter_ids = UserPage.twitter_ids(usernames, limit)
    p twitter_ids
    p twitter_ids.size

    list = twitter_client.lists.select{|list| list.name == "atcoder-tl-#{color}"}.first
    twitter_ids.each_slice(100) do |ids|
      twitter_client.add_list_members(list, ids)
    end
    p "finished #{color}"
  end
end

main(limit=10000)
