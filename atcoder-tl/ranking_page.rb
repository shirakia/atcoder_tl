require_relative 'page'

module RankingPage
  class << self
    include Page

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

    def usernames(rating)
      usernames = []
      page = 1
      while true
        url = url(*rating, page)
        p url
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
