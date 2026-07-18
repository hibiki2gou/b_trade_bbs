# 選手の所属チームを「文字列」から「Team への参照」に置き換える。
#
# before: players.team （"横浜BC" という文字列）
# after : players.team_id （teams テーブルの1行を指す）
#
# これでチームが独立した「モノ」になり、チーム側から選手一覧を辿ったり、
# チームに画像・並び順を持たせたりできるようになる。
class ReplacePlayerTeamWithReference < ActiveRecord::Migration[8.1]
  def change
    # 古い文字列カラムを削除。
    # （down / rollback 時に復元できるよう、型 :string を書いておく）
    remove_column :players, :team, :string

    # Team への参照を追加。null: false = チーム未所属の選手は作れない。
    # foreign_key: true = teams テーブルに実在する行しか指せない
    add_reference :players, :team, null: false, foreign_key: true
  end
end
