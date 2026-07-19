# 募集（Post）の投稿・成立を担当するコントローラ。
class PostsController < ApplicationController
  # 連投対策。同じ人が1分間に投稿できるのは10回まで。
  # 超えたら投稿元の画面に戻して知らせる（Rails 8 標準の rate_limit）。
  rate_limit to: 10, within: 1.minute, only: :create,
             with: -> { redirect_back fallback_location: root_path,
                                      alert: "投稿が多すぎます。少し時間をおいてください。" }

  # 募集を投稿する。
  def create
    @post = Post.new(post_params)
    if @post.save
      # 投稿元の掲示板に戻る（戻れなければトップへ）。
      redirect_back fallback_location: root_path, notice: "募集を投稿しました。"
    else
      # 失敗したら、投稿元の掲示板をエラー付きで再表示する。
      # （エラーはフォームの中に出る。ページ上部には出さない）
      render_board_with_errors
    end
  end

  # トレード成立にする（成立ボタン）。
  def complete
    @post = Post.find(params[:id])
    @post.complete!
    redirect_back fallback_location: root_path, notice: "トレード成立にしました。"
  end

  private

  def post_params
    # wanted_card_ids / offered_card_ids は複数選択。どちらも配列で受け取る。
    params.require(:post).permit(:note, :nickname,
                                 wanted_card_ids: [], offered_card_ids: [])
  end

  # 投稿に失敗したとき、投稿元の掲示板（弾 or チーム）を組み立てて
  # エラー付きの @post のまま再表示する。show アクションと同じ変数を用意する。
  def render_board_with_errors
    @showing_completed = false
    @offered_options = Card.includes(:player, :topic).to_a.sort_by(&:picker_label)

    if params[:board_type] == "team" && params[:board_id].present?
      @team = Team.find(params[:board_id])
      @posts = Post.wanting_team(@team).open_posts
                   .recent.includes(wanted_cards: :player, offered_cards: :player)
      @wanted_options = @team.cards.includes(:player, :topic).sort_by(&:picker_label)
      render "teams/show", status: :unprocessable_entity
    elsif params[:board_id].present?
      @topic = Topic.find(params[:board_id])
      @posts = Post.wanting_topic(@topic).open_posts
                   .recent.includes(wanted_cards: :player, offered_cards: :player)
      @wanted_options = @topic.cards.includes(:player).sort_by(&:label)
      render "topics/show", status: :unprocessable_entity
    else
      # 投稿元が分からない場合の保険
      redirect_back fallback_location: root_path,
                    alert: "投稿できませんでした: #{@post.errors.full_messages.join('、')}"
    end
  end
end
