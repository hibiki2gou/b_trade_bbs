require "test_helper"

# カード一覧（/cards）の絞り込みが効いているかを確かめる。
class CardsControllerTest < ActionDispatch::IntegrationTest
  setup do
    board  = Board.create!(name: "トレード募集", slug: "trade")
    @wave1 = board.topics.create!(name: "第1弾", slug: "wave-1", position: 1)
    @wave2 = board.topics.create!(name: "第2弾", slug: "wave-2", position: 2)
    @chiba = Team.create!(name: "千葉ジェッツ", slug: "chiba-jets", position: 1)
    @tokyo = Team.create!(name: "アルバルク東京", slug: "alvark-tokyo", position: 2)

    @tomi = Player.create!(name: "富樫勇樹", team: @chiba, jersey_number: 2)
    @ando = Player.create!(name: "安藤周人", team: @tokyo, jersey_number: 9)

    @a = Card.create!(topic: @wave1, team: @chiba, players: [ @tomi ], rarity: 5)
    @b = Card.create!(topic: @wave1, team: @tokyo, players: [ @ando ], rarity: 4)
    @c = Card.create!(topic: @wave2, team: @chiba, name: "千葉ジェッツ", rarity: 4)
  end

  test "絞り込みなしなら全部出る" do
    get cards_path
    assert_response :success
    assert_select ".cardchip", 3
  end

  test "弾で絞り込める" do
    get cards_path(topic_id: @wave2.id)
    assert_select ".cardchip", 1
    assert_select ".cardchip", text: /千葉ジェッツ/
  end

  test "クラブで絞り込める" do
    get cards_path(team_id: @tokyo.id)
    assert_select ".cardchip", 1
    assert_select ".cardchip", text: /安藤周人/
  end

  test "レア度で絞り込める" do
    get cards_path(rarity: 5)
    assert_select ".cardchip", 1
    assert_select ".cardchip", text: /富樫勇樹/
  end

  test "選手名で検索できる" do
    get cards_path(q: "安藤")
    assert_select ".cardchip", 1
    assert_select ".cardchip", text: /安藤周人/
  end

  test "カードに写っていないクラブ名でも、そのカードのクラブなら引っかかる" do
    get cards_path(q: "アルバルク")
    assert_select ".cardchip", 1
  end

  test "条件は組み合わせられる" do
    get cards_path(topic_id: @wave1.id, team_id: @chiba.id)
    assert_select ".cardchip", 1
    assert_select ".cardchip", text: /富樫勇樹/
  end

  test "該当なしのときは0枚と伝える" do
    get cards_path(q: "存在しない選手")
    assert_select ".cardchip", 0
    assert_select ".muted", text: /ありませんでした/
  end

  test "弾ごとに区切るので、カード内に弾名は重ねて出さない" do
    get cards_path
    assert_select ".cards__heading", text: /第1弾/
    assert_select ".cardchip__set", 0
  end
end
