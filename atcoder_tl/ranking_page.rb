require_relative 'util'

module RankingPage
  class << self
    include Util

    # Returns a list consisting of struct(username, rank, rating)
    def users()
      users = []
      page = 1
      while true
        url = url(page)
        $logger.info "Downloading #{url}"

        html = download(url)
        users_on_page, is_last_page = parse(html)
        users.concat users_on_page

        break if is_last_page
        page += 1
      end

      users
    end

    def url(page)
      options = {
        'page' => page,
      }
      "https://atcoder.jp/ranking?" + options.map{ |h| h.join('=') }.join('&')
    end

    def parse(html)
      user = Struct.new(:username, :rank, :rating)
      doc = Nokogiri::HTML.parse(html, nil, 'utf-8')
      entries = doc.css('tbody').css('tr')
      result = []
      for entry in entries
        rank = entry.children[1].text.to_i
        username = entry.children[3].css('span')[0].text
        country_image_url = entry.children[3].css('img')[0]['src'] # the image representing the country always comes first. Crowns, if present, follow.
        rating = entry.children[7].text.to_i
        if country_image_url == '//img.atcoder.jp/assets/flag/JP.png'
          result.append user.new(username, rank, rating)
        end
      end
      is_last_page = entries.size < 100
      [result, is_last_page]
    end
  end
end
