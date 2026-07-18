require "test_helper"

class TeamsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @team = Team.create!(name: "チームA", slug: "team-a", position: 1)
  end

  test "チーム一覧が表示できる" do
    get teams_url
    assert_response :success
    assert_select "h1, a", text: /チームA|チームで見る/
  end

  test "チームの掲示板が表示できる" do
    get team_url(@team)
    assert_response :success
    assert_select "h1", text: "チームA"
  end
end
