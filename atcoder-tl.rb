require 'uri'
require 'net/http'

require "rubygems"
require 'pry'
require 'nokogiri'

COLORS = {
  red: [2800, 9999],
#   orange: [2400, 2799]
#   yellow: [2000, 2399]
#   blue: [1600, 1999]
#   cyan: [1200, 1599]
#   green: [800, 1199]
#   brown: [400, 799]
#   gray: [0, 399]
}

ATCODER_URL = 'https://atcoder.jp/'

def ranking_url(rating_lower_bound=0, rating_upper_bound=9999, page=1)
  options = {
    'f.Country' => 'JP',
    'f.RatingLowerBound' => rating_lower_bound,
    'f.RatingUpperBound' => rating_upper_bound,
    'page' => page,
  }
  ATCODER_URL + "ranking?" + options.map{ |h| h.join('=') }.join('&')
end

def user_url(user_id)
  ATCODER_URL + "users/" + user_id
end

def download(url)
  sleep(1)

  uri = URI.parse(url)
  response = Net::HTTP.get_response(uri)
  case response
  when Net::HTTPNotFound
    raise "HTTP not found"
  else
    response.body
  end
end

def parse_ranking_page(html)
  doc = Nokogiri::HTML.parse(html, nil, 'utf-8')
  doc.css('#main-container a.username').map(&:text)
end

def parse_user_page(html)
  doc = Nokogiri::HTML.parse(html, nil, 'utf-8')

  trs = doc.css('#main-container > div.row > div.col-sm-3 > table > tr')
  twitter_tr = trs.select{ |tr| tr.css('th').text == 'Twitter ID' }

  return nil if twitter_tr.empty?
  twitter_tr.first.css('td').text
end

def main(limit)
  COLORS.each do |color, rating|
    usernames = []
    page = 1
    while true
      url = ranking_url(*rating, page)
      p url
      html = download(url)
      users_on_page = parse_ranking_page(html)
      break if users_on_page.empty?

      usernames.concat users_on_page

      page += 1
      break # TODO
    end

    twitter_ids = usernames.first(limit).map do |username|
      url = user_url(username)
      html = download(url)
      parse_user_page(html)
    end
  end
end

# main(limit=3)
