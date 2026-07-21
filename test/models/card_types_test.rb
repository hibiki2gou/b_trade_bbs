require "test_helper"

# カードの3つの種類（選手1人／複数選手／クラブ）が扱えることを確かめる。
class CardTypesTest < ActiveSupport::TestCase
  setup do
    board  = Board.create!(name: "トレード募集", slug: "trade")
    @topic = board.topics.create!(name: "弾A", slug: "set-a", position: 1)
    @chiba = Team.create!(name: "千葉ジェッツ", slug: "chiba-jets", position: 1)
    @tokyo = Team.create!(name: "アルバルク東京", slug: "alvark-tokyo", position: 2)
    @bleague = Team.create!(name: "B.LEAGUE", slug: "bleague", position: 99)

    @p1 = Player.create!(name: "選手A", team: @chiba, jersey_number: 2)
    @p2 = Player.create!(name: "選手B", team: @tokyo, jersey_number: 3)
  end

  test "選手1人のカードは選手名がそのまま表示名になる" do
    card = Card.create!(topic: @topic, team: @chiba, players: [ @p1 ], rarity: 5)
    assert_equal "選手A", card.label
    assert_equal @chiba, card.team
  end

  test "選手1人でもカード名があれば添えて表示する" do
    card = Card.create!(topic: @topic, team: @chiba, players: [ @p1 ],
                        name: "得点記録", rarity: 5)
    assert_equal "選手A（得点記録）", card.label
  end

  test "複数選手のカードはカード名を表示し、B.LEAGUE に属せる" do
    card = Card.create!(topic: @topic, team: @bleague, players: [ @p1, @p2 ],
                        name: "選手A vs 選手B", rarity: 5)
    assert_equal "選手A vs 選手B", card.label
    assert_equal 2, card.players.count
    assert_equal @bleague, card.team
  end

  test "クラブカードは選手が0人でも作れる" do
    card = Card.create!(topic: @topic, team: @chiba, name: "千葉ジェッツ", rarity: 4)
    assert_equal "千葉ジェッツ", card.label
    assert_equal 0, card.players.count
  end

  test "選手が1人でないカードは name が無いと作れない" do
    card = Card.new(topic: @topic, team: @chiba, rarity: 4)  # 選手0人・name無し
    assert_not card.valid?
    assert_includes card.errors[:name].join, "必要"
  end

  test "同じ弾に同じ内容のカードは二重登録できない" do
    Card.create!(topic: @topic, team: @chiba, players: [ @p1 ], rarity: 5)
    dup = Card.new(topic: @topic, team: @chiba, players: [ @p1 ], rarity: 5)
    assert_not dup.valid?, "同じ選手・同じ弾・同じ名前は重複"
  end

  test "チームの掲示板は、カードが持つチームで拾う（選手からたどらない）" do
    # 千葉と東京の選手が写るカードだが、所属は B.LEAGUE
    card = Card.create!(topic: @topic, team: @bleague, players: [ @p1, @p2 ],
                        name: "選手A vs 選手B", rarity: 5)
    post = Post.create!(nickname: "太郎", wanted_cards: [ card ])

    assert_includes Post.wanting_team(@bleague), post, "B.LEAGUE の掲示板に出る"
    assert_not_includes Post.wanting_team(@chiba), post, "千葉の掲示板には出ない"
  end
end
