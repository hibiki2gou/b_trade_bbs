# Post = 募集（トレードの書き込み）。
# 「このカードが欲しい／これを出せる」を1つの書き込みにまとめる。
class CreatePosts < ActiveRecord::Migration[8.1]
  def change
    create_table :posts do |t|
      # どの弾スレッドへの書き込みか
      t.references :topic, null: false, foreign_key: true

      # 欲しいカード。選択式なので cards テーブルの1枚を指す。
      # カラム名は wanted_card_id だが、参照先は cards テーブルなので
      # to_table: :cards を明示する（これを書かないと存在しない
      # wanted_cards テーブルを探しに行ってしまう）
      t.references :wanted_card, null: false,
                   foreign_key: { to_table: :cards }

      # 出せるカード。全弾から来るので選択式にはせず、自由入力のテキスト。
      # 「交渉で」と書く人もいるので必須にはしない
      t.text :offered_cards
      # 備考欄（よろしくお願いします、希望する交換方法 など）。任意
      t.text :note
      # 投稿者のニックネーム。ログイン機能を付けるまでは手入力
      t.string :nickname, null: false

      # 募集の状態。0 = 募集中、1 = 成立済み。既定は募集中
      t.integer :status, null: false, default: 0
      # トレードが成立した日時。成立ボタンを押すまでは空
      t.datetime :completed_at

      t.timestamps
    end
    # 「募集中だけ表示」「成立済みだけ表示」を速く引くための索引
    add_index :posts, :status
  end
end
