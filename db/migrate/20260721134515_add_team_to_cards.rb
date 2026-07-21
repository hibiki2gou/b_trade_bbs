# カード自身に「所属チーム」を持たせる。
#
# これまではカード → 選手 → チーム とたどってチームを決めていたが、
# 次のカードが表現できなかった。
#   - クラブを扱ったカード（選手が写っていない）
#   - 別チームの選手を扱ったカード（どのクラブにも属さず B.LEAGUE 扱い）
#
# カードが直接チームを持つことで、これらを素直に表せる。
class AddTeamToCards < ActiveRecord::Migration[8.1]
  def up
    add_reference :cards, :team, foreign_key: true

    # 既存のカードは、写っている選手の所属チームで埋める
    execute <<~SQL
      UPDATE cards
      SET team_id = (
        SELECT players.team_id FROM players WHERE players.id = cards.player_id
      )
    SQL

    change_column_null :cards, :team_id, false
  end

  def down
    remove_reference :cards, :team, foreign_key: true
  end
end
