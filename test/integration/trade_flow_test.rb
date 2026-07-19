require "test_helper"

# 募集の投稿 → 表示 → 成立 の一連の流れが動くかを、
# 実際の HTTP リクエスト（ルーティング→コントローラ→モデル）で確かめる。
class TradeFlowTest < ActionDispatch::IntegrationTest
  setup do
    board = Board.create!(name: "トレード募集", slug: "trade")
    @topic = board.topics.create!(name: "弾A", slug: "set-a", position: 1)
    @team  = Team.create!(name: "チームA", slug: "team-a", position: 1)
    player = Player.create!(name: "選手A", team: @team)
    @wanted1 = Card.create!(topic: @topic, player: player, rarity: 5)
    @wanted2 = Card.create!(topic: @topic, player: player, name: "アシスト記録", rarity: 4)
    @offered = Card.create!(topic: @topic, player: player, name: "得点記録", rarity: 4)
  end

  test "募集を投稿すると、欲しいカード（複数）と出せるカードが紐づく" do
    assert_difference "Post.count", 1 do
      post posts_path, params: { post: {
        wanted_card_ids: [ @wanted1.id, @wanted2.id ],
        offered_card_ids: [ @offered.id ],
        nickname: "太郎",
        note: "よろしく"
      } }
    end

    p = Post.last
    assert_equal [ @wanted1, @wanted2 ].sort, p.wanted_cards.sort, "欲しいカードが複数紐づく"
    assert_equal [ @offered ], p.offered_cards.to_a, "出せるカードが紐づく"
    assert p.open?, "投稿直後は募集中"
  end

  test "投稿した募集は、欲しいカードの弾の掲示板から見える" do
    post posts_path, params: { post: { wanted_card_ids: [ @wanted1.id ], nickname: "太郎" } }
    assert_includes Post.wanting_topic(@topic), Post.last
  end

  test "投稿した募集は、欲しいカードのチームの掲示板からも見える" do
    post posts_path, params: { post: { wanted_card_ids: [ @wanted1.id ], nickname: "太郎" } }
    assert_includes Post.wanting_team(@team), Post.last
  end

  test "成立ボタンで状態が成立済みになり、募集中一覧から外れる" do
    post posts_path, params: { post: { wanted_card_ids: [ @wanted1.id ], nickname: "太郎" } }
    p = Post.last

    patch complete_post_path(p)
    assert p.reload.completed?, "成立済みになる"
    assert p.completed_at.present?, "成立日時が記録される"
    assert_not_includes Post.wanting_topic(@topic).open_posts, p, "募集中一覧から外れる"
  end

  test "欲しいカードを1枚も選ばないと投稿できない" do
    assert_no_difference "Post.count" do
      post posts_path, params: { post: { nickname: "太郎" } }
    end
  end

  test "ニックネームが空だと投稿できない" do
    assert_no_difference "Post.count" do
      post posts_path, params: { post: { wanted_card_ids: [ @wanted1.id ], nickname: "" } }
    end
  end

  test "投稿に失敗すると、掲示板を再表示してフォーム内にエラーを出す" do
    post posts_path, params: {
      board_type: "topic", board_id: @topic.id,
      post: { wanted_card_ids: [ @wanted1.id ], nickname: "" }
    }
    assert_response :unprocessable_entity
    assert_select ".form-errors", true, "フォーム内にエラー欄が出る"
    assert_select "form.post-form"
    # 失敗時は開閉フォームが自動で開いている（エラーが見えるように）
    assert_select "details.new-post[open]"
  end
end
