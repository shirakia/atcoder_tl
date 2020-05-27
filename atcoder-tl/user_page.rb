require_relative 'util'

module UserPage
  class << self
    include Util

    def twitter_ids(usernames)
      usernames.map.with_index do |username, i|
        logger.info "Collecting Twitter ID progress: #{i}" if i % 100 == 0
        url = url(username)
        html = download(url)
        parse(html)
      end.compact.sort
    end

    def url(user_id)
      'https://atcoder.jp/users/' + user_id
    end

    def parse(html)
      doc = Nokogiri::HTML.parse(html, nil, 'utf-8')

      trs = doc.css('#main-container > div.row > div.col-sm-3 > table > tr')
      twitter_tr = trs.select{ |tr| tr.css('th').text == 'Twitter ID' }
      return nil if twitter_tr.empty?

      twitter_id = twitter_tr.first.css('td').text
      twitter_id.slice!(0) # @shirakia -> shirakia
      twitter_id
    end
  end
end
