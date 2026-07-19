# 欲しいカードを「1枚（wanted_card_id）」から「複数（Wish 経由）」に変えたので、
# posts の古いカラムを削除する。
#
# - wanted_card_id : 欲しいカード1枚への参照 → Wish で複数持つようになった
# - topic_id       : 所属する弾1つ → 欲しいカードが複数弾にまたがりうるので廃止。
#                    どの掲示板に出るかは欲しいカードから導く。
class RemoveWantedCardAndTopicFromPosts < ActiveRecord::Migration[8.1]
  def change
    # rollback 時に復元できるよう、型や参照先を書いておく
    remove_reference :posts, :wanted_card, foreign_key: { to_table: :cards }
    remove_reference :posts, :topic, foreign_key: true
  end
end
