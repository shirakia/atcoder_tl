require_relative 'util'

module RankingPage
  class << self
    include Util

    def usernames(color)
      usernames = []
      page = 1
      while true
        url = url(color.rating_lb, color.rating_ub, page)
        $logger.info "[#{color.name}] Downloading #{url}"

        html = download(url)
        usernames_on_page = parse(html)
        usernames.concat usernames_on_page

        break if last_page?(usernames_on_page)
        page += 1
      end

      usernames
    end

    def last_page?(usernames_on_page)
      usernames_on_page.size < 100
    end

    def url(rating_lower_bound, rating_upper_bound, page)
      options = {
        'f.Country' => 'JP',
        'f.RatingLowerBound' => rating_lower_bound,
        'f.RatingUpperBound' => rating_upper_bound,
        'page' => page,
      }
      "https://atcoder.jp/ranking?" + options.map{ |h| h.join('=') }.join('&')
    end

    def parse(html)
      doc = Nokogiri::HTML.parse(html, nil, 'utf-8')
      doc.css('#main-container a.username').map(&:text)
    end
  end
end
