Rails.application.routes.draw do
  # 弾（Topic）のページ。
  #   index … 弾の一覧        GET /topics       （topics_path）
  #   show  … 弾ごとの掲示板   GET /topics/:id   （topic_path(topic)）
  # only: で、今使う index と show の2つだけルートを作る。
  resources :topics, only: [ :index, :show ]

  # クラブチーム（Team）のページ。弾と同じ作り。
  #   index … チームの一覧      GET /teams
  #   show  … チームごとの掲示板 GET /teams/:id
  resources :teams, only: [ :index, :show ]

  # カード（Card）の一覧。全弾のカードを横断して探せるページ。
  #   index … カード一覧  GET /cards （cards_path）
  # 絞り込みは ?topic_id=&team_id=&rarity=&q= をつけて表現する。
  resources :cards, only: [ :index ]

  # 募集（Post）。
  #   create   … 募集を投稿する          POST  /posts
  #   complete … トレード成立にする（member=特定の1件に対する操作）
  #              PATCH /posts/:id/complete
  resources :posts, only: [ :create ] do
    member do
      patch :complete
    end
  end

  # トップページ（/）は弾の一覧を表示する
  root "topics#index"

  # アプリが正常に起動しているかを返す死活監視用のURL（Rails 標準）
  get "up" => "rails/health#show", as: :rails_health_check
end
