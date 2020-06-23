require_relative 'util'

class StandingsPage
  include Util

  def initialize(contest_name)
    url = "https://atcoder.jp/contests/#{contest_name}/results/json"
    json = download(url)
    @standings = JSON.parse(json)
    @standings.select!{|row| row['IsRated'] && row['Country'] == 'JP'}.
      map!{|row| row.slice('UserScreenName', 'NewRating', 'OldRating')}
  end

  def users_to_be_added(color)
    @standings.select do |row|
      color.rating_lb <= row['NewRating'] && row['NewRating'] <= color.rating_ub &&
        (row['OldRating'] < color.rating_lb || color.rating_ub < row['OldRating'])
    end
  end

  def users_to_be_removed(color)
    @standings.select do |row|
      color.rating_lb <= row['OldRating'] && row['OldRating'] <= color.rating_ub &&
        (row['NewRating'] < color.rating_lb || color.rating_ub < row['NewRating'])
    end
  end

  def users_comming_up(color)
    @standings.select do |row|
      color.rating_lb <= row['NewRating'] && row['NewRating'] <= color.rating_ub &&
        row['OldRating'] < color.rating_lb
    end
  end

  def users_going_down(color)
    @standings.select do |row|
      color.rating_lb <= row['OldRating'] && row['OldRating'] <= color.rating_ub &&
        row['NewRating'] < color.rating_lb
    end
  end
end
