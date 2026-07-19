require "test_helper"

class TopicsControllerTest < ActionDispatch::IntegrationTest
  setup do
    board = Board.create!(name: "トレード募集", slug: "trade")
    @topic = board.topics.create!(name: "弾A", slug: "set-a", position: 1)
    team = Team.create!(name: "チームA", slug: "team-a", position: 1)
    player = Player.create!(name: "選手A", team: team)
    @card = Card.create!(topic: @topic, player: player, name: "得点記録", rarity: 5)
  end

  test "弾一覧が表示できる" do
    get topics_url
    assert_response :success
    assert_select "h1, a", text: /弾A|弾で見る/
  end

  test "弾の掲示板が表示できる" do
    get topic_url(@topic)
    assert_response :success
    assert_select "h1", text: "弾A"
  end

  test "一覧へもどるリンクは弾一覧を指す（history.back に頼らない）" do
    get topic_url(@topic)
    assert_select "a.board-header__back[href=?]", topics_path
  end

  test "弾の掲示板に収録カード一覧がモーダルで用意される" do
    get topic_url(@topic)
    assert_select "dialog.modal"
    assert_select ".cardlist__item", text: /選手A（得点記録）/
  end

  test "弾を削除できる（廃止したカラムを参照する関連が残っていないこと）" do
    # posts.topic_id を廃止したのに Topic に has_many :posts が残っていると、
    # 削除時に存在しないカラムを探して落ちる。
    assert_nothing_raised { @topic.destroy! }
    assert_not Topic.exists?(@topic.id)
  end

  test "モーダルの display 指定は開いているときだけに限定されている" do
    # .modal { display: flex } と無条件に書くと、閉じた <dialog> をブラウザが
    # 隠す動作（display:none）を上書きしてしまい、常に表示されてしまう。
    css = Rails.root.join("app/assets/stylesheets/application.css").read
    modal_block = css[/^\.modal \{[^}]*\}/m]
    assert_no_match(/display:/, modal_block.to_s,
                    ".modal に無条件の display を書くと閉じても消えなくなる")
    assert_match(/\.modal\[open\][^{]*\{[^}]*display:\s*flex/m, css,
                 "display は .modal[open] に限定して指定すること")
  end

  test "通常表示ではモーダルを自動で開く指定が出ない" do
    # data-modal-open-value="false" と書くと Stimulus は「属性がある＝真」と
    # 解釈して勝手に開いてしまう。属性そのものが出ないことを確かめる。
    get topic_url(@topic)
    assert_select "[data-modal-open-value]", false,
                  "エラーが無いときは open 指定を出さない（出すと勝手に開く）"
  end
end
