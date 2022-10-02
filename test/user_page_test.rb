require 'date'
require 'minitest/autorun'
require 'nokogiri'

require_relative '../atcoder_tl/user_page'

class UserPageTest < Minitest::Test
  def test_parse
    File.open(File.expand_path('../sample/user_page.html', __FILE__)) do |f|
      html = f.read
      ret = UserPage.parse(html)

      assert_equal ret[:tid], 'snuke_'
      assert_equal ret[:last_competed], Date.new(2022, 8, 14)
    end
  end
end
