# Team = クラブチーム。弾(Topic)と同じく、名前・slug・画像・並び順を持つ「モノ」。
# 選手(Player)がどのチームに所属するかを表す。
class CreateTeams < ActiveRecord::Migration[8.1]
  def change
    create_table :teams do |t|
      # チーム名。画面に表示される。例: 横浜ビー・コルセアーズ
      t.string :name, null: false
      # URL・画像ファイル名に使う名札。例: yokohama-bc
      t.string :slug, null: false
      # 一覧に並べる順番
      t.integer :position, null: false, default: 0

      t.timestamps
    end
    # slug は URL の identity なので重複禁止
    add_index :teams, :slug, unique: true
  end
end
