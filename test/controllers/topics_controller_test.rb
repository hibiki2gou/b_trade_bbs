require "test_helper"

class TopicsControllerTest < ActionDispatch::IntegrationTest
  setup do
    board = Board.create!(name: "トレード募集", slug: "trade")
    @topic = board.topics.create!(name: "弾A", slug: "set-a", position: 1)
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
    assert_select "a.back-link, .back a[href=?]", topics_path, text: /一覧へもどる/
  end
end
