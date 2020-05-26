require_relative 'page'

module UserPage
  class << self
    include Page

    def twitter_ids(usernames, limit)
      usernames.first(limit).map do |username|
        url = url(username)
        html = download(url)
        parse(html)
      end.compact
    end

    def url(user_id)
      'https://atcoder.jp/users/' + user_id
    end

    def parse(html)
      doc = Nokogiri::HTML.parse(html, nil, 'utf-8')

      trs = doc.css('#main-container > div.row > div.col-sm-3 > table > tr')
      twitter_tr = trs.select{ |tr| tr.css('th').text == 'Twitter ID' }

      return nil if twitter_tr.empty?
      twitter_tr.first.css('td').text
    end
  end
end
