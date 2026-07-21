# クラブチーム（Team）のページを担当するコントローラ。弾とほぼ同じ作り。
class TeamsController < ApplicationController
  # チームの一覧。チームをグリッドで並べる。
  def index
    @teams = Team.ordered
  end

  # チームごとの掲示板。そのチームのカードを欲しがっている募集を表示する。
  def show
    @team = Team.find(params[:id])

    # ?status=completed のときだけ成立済みを表示。既定は募集中。
    @showing_completed = params[:status] == "completed"
    posts = Post.wanting_team(@team)
    posts = @showing_completed ? posts.completed_posts : posts.open_posts
    @posts = posts.recent.includes(wanted_cards: :players, offered_cards: :players)

    # このチームのカード一覧（弾をまたぐので弾名も見せる）。
    # 弾の並び順（新しい順）→ 背番号順。背番号なしは最後にする。
    @cards = @team.cards.includes(:topic, :players)
                  .sort_by { |c| [ c.topic.position, c.sort_number ] }

    # 投稿フォーム用。
    @post = Post.new
    # 欲しいカードの選択肢はこのチームのカード（弾をまたぐ）。
    @wanted_options = @cards
    # 出せるカードの選択肢は全カード（全弾から選べる）。
    @offered_options = Card.includes(:players, :topic, :team).to_a.sort_by(&:picker_label)
  end
end
