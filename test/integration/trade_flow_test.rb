require "test_helper"

# 募集の投稿 → 表示 → 成立 の一連の流れが動くかを、
# 実際の HTTP リクエスト（ルーティング→コントローラ→モデル）で確かめる。
class TradeFlowTest < ActionDispatch::IntegrationTest
  setup do
    board = Board.create!(name: "トレード募集", slug: "trade")
    @topic = board.topics.create!(name: "弾A", slug: "set-a", position: 1)
    @team  = Team.create!(name: "チームA", slug: "team-a", position: 1)
    player = Player.create!(name: "選手A", team: @team)
    @wanted  = Card.create!(topic: @topic, player: player, rarity: 5)
    @offered = Card.create!(topic: @topic, player: player, name: "得点記録", rarity: 4)
  end

  test "募集を投稿すると一覧に増え、弾が自動設定され、出せるカードも紐づく" do
    assert_difference "Post.count", 1 do
      post posts_path, params: { post: {
        wanted_card_id: @wanted.id,
        nickname: "太郎",
        note: "よろしく",
        offered_card_ids: [ @offered.id ]
      } }
    end
    assert_redirected_to topic_path(@topic)

    p = Post.last
    assert_equal @topic, p.topic, "弾は欲しいカードから自動設定される"
    assert_equal [ @offered ], p.offered_cards.to_a, "出せるカードが紐づく"
    assert p.open?, "投稿直後は募集中"
  end

  test "投稿した募集は、欲しいカードのチームの掲示板からも見える" do
    post posts_path, params: { post: { wanted_card_id: @wanted.id, nickname: "太郎" } }
    p = Post.last
    assert_includes Post.wanting_team(@team), p
  end

  test "成立ボタンで状態が成立済みになり、募集中一覧から外れる" do
    post posts_path, params: { post: { wanted_card_id: @wanted.id, nickname: "太郎" } }
    p = Post.last

    patch complete_post_path(p)
    assert p.reload.completed?, "成立済みになる"
    assert p.completed_at.present?, "成立日時が記録される"
    assert_not_includes @topic.posts.open_posts, p, "募集中一覧から外れる"
  end

  test "ニックネームが空だと投稿できない" do
    assert_no_difference "Post.count" do
      post posts_path, params: { post: { wanted_card_id: @wanted.id, nickname: "" } }
    end
  end
end
