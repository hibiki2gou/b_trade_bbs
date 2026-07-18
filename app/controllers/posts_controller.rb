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
      # 投稿元の掲示板に戻る。戻れなければ、その募集の弾の掲示板へ。
      redirect_back fallback_location: topic_path(@post.topic),
                    notice: "募集を投稿しました。"
    else
      redirect_back fallback_location: root_path,
                    alert: "投稿できませんでした: #{@post.errors.full_messages.join('、')}"
    end
  end

  # トレード成立にする（成立ボタン）。
  def complete
    @post = Post.find(params[:id])
    @post.complete!
    redirect_back fallback_location: topic_path(@post.topic),
                  notice: "トレード成立にしました。"
  end

  private

  def post_params
    # offered_card_ids は「出せるカード」の複数選択。配列で受け取る。
    params.require(:post).permit(:wanted_card_id, :note, :nickname, offered_card_ids: [])
  end
end
