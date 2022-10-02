require 'minitest/autorun'
require 'nokogiri'

require_relative '../atcoder_tl/ranking_page'

class RankingPageTest < Minitest::Test
  def test_parse
    File.open(File.expand_path('../sample/ranking_page.html', __FILE__)) do |f|
      html = f.read
      users_on_page, is_last_page = RankingPage.parse(html)

      assert_equal users_on_page.size, 36 # 36 JP users
      assert_equal users_on_page[0].username, 'risujiroh'
      assert_equal users_on_page[-1].rating, 2663
      assert_equal is_last_page, false
    end
  end
end
