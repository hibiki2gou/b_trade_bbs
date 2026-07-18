# 出せるカードを「文字列」から「カードの選択（Offer 経由）」に変えたので、
# posts の古い文字列カラム offered_cards を削除する。
class RemoveOfferedCardsFromPosts < ActiveRecord::Migration[8.1]
  def change
    # down / rollback 時に復元できるよう、型 :text を書いておく
    remove_column :posts, :offered_cards, :text
  end
end
