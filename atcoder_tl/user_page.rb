require_relative 'util'

module UserPage
  class << self
    include Util

    def users(usernames, color)
      info = usernames.map.with_index do |username, i|
        logger.info "[#{color.name}] Collecting Twitter ID progress: #{i}" if i % 100 == 0
        url = url(username)

        begin
          html = download(url)
          parse(html)
        rescue
          logger.warn "[#{color.name}] 404 or parse error:  #{url}"
          nil
        end
      end

      usernames.zip(info).to_h
    end

    def url(user_id)
      'https://atcoder.jp/users/' + user_id
    end

    def parse(html)
      doc = Nokogiri::HTML.parse(html, nil, 'utf-8')

      trs_left = doc.css('#main-container > div.row > div.col-sm-3 > table > tr')
      twitter_tr = trs_left.select{ |tr| tr.css('th').text == 'Twitter ID' }

      if twitter_tr.any?
        twitter_id = twitter_tr.first.css('td').text
        # @shirakia -> shirakia と変換。間違って @@shirakia のように登録している人が
        # 複数人観測されるため、slice!ではなくdelete!('@')
        twitter_id.delete!('@')
        twitter_id.downcase!
      end

      trs_right = doc.css('#main-container > div.row > div.col-sm-9 > table > tr')
      last_competed_tr = trs_right.select{ |tr| tr.css('th').text == 'Last Competed' }
      last_competed = Date.parse(last_competed_tr.first.css('td').text)

      {
        twitter_id: twitter_id,
        last_competed: last_competed
      }
    end
  end
end
