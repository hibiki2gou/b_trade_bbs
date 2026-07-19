# 弾（Topic）のページを担当するコントローラ。
class TopicsController < ApplicationController
  # 弾の一覧（トップページ）。弾をグリッドで並べる。
  def index
    @topics = Topic.ordered
  end

  # 弾ごとの掲示板。その弾への募集一覧と、投稿フォームを表示する。
  def show
    @topic = Topic.find(params[:id])

    # ?status=completed のときだけ成立済みを表示。既定は募集中。
    # この弾のカードを1枚でも欲しがっている募集を表示する。
    @showing_completed = params[:status] == "completed"
    posts = Post.wanting_topic(@topic)
    posts = @showing_completed ? posts.completed_posts : posts.open_posts
    @posts = posts.recent.includes(wanted_cards: :player, offered_cards: :player)

    # 投稿フォーム用。
    @post = Post.new
    # 欲しいカードの選択肢はこの弾のカード。
    @wanted_options = @topic.cards.includes(:player).sort_by(&:label)
    # 出せるカードの選択肢は全カード（全弾から選べる）。
    @offered_options = Card.includes(:player, :topic).to_a.sort_by(&:picker_label)
  end
end
