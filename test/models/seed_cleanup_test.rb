require "test_helper"

# seed が「YAML から消えた弾・チーム」を後始末するときの安全装置を確かめる。
# 空のものは消してよいが、データが紐づいているものは消してはいけない。
class SeedCleanupTest < ActiveSupport::TestCase
  setup do
    @board = Board.create!(name: "トレード募集", slug: "trade")
    @team  = Team.create!(name: "チームA", slug: "team-a", position: 1)
  end

  test "カードが紐づいた弾は削除対象にならない" do
    topic  = @board.topics.create!(name: "弾A", slug: "set-a", position: 1)
    player = Player.create!(name: "選手A", team: @team)
    Card.create!(topic: topic, player: player, rarity: 5)

    assert topic.cards.exists?, "カードがあるので守られる側"
  end

  test "募集から欲しがられている弾は削除対象にならない" do
    topic  = @board.topics.create!(name: "弾B", slug: "set-b", position: 2)
    player = Player.create!(name: "選手B", team: @team)
    card   = Card.create!(topic: topic, player: player, rarity: 4)
    Post.create!(nickname: "太郎", wanted_cards: [ card ])

    assert Post.wanting_topic(topic).exists?, "募集があるので守られる側"
  end

  test "空の弾は削除できる" do
    topic = @board.topics.create!(name: "空の弾", slug: "empty", position: 3)

    assert_not topic.cards.exists?
    assert_not Post.wanting_topic(topic).exists?
    assert_nothing_raised { topic.destroy! }
  end

  test "選手が所属するチームは削除対象にならない" do
    Player.create!(name: "選手C", team: @team)
    assert @team.players.exists?, "選手がいるので守られる側"
  end
end
