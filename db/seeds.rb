# ============================================================
# 初期データ投入
#
#     docker compose exec web bin/rails db:seed
#
# db/seeds/card_sets.yml を読み込んで、弾・チーム・選手・カードを登録する。
# 何度実行しても同じ結果になる（冪等）。利用者の投稿(Post)には触れない。
# ============================================================

# --- 1. YAML を読み込む ------------------------------------------------
yaml_path = Rails.root.join("db/seeds/card_sets.yml")
data = YAML.load_file(yaml_path)
sets     = data["sets"]     || []
teams    = data["teams"]    || []
players  = data["players"]  || []
lineups  = data["lineups"]  || []

set_slugs    = sets.map    { |s| s["slug"] }
team_slugs   = teams.map   { |t| t["slug"] }
player_names = players.map { |p| p["name"] }

# カード1件に写っている選手名を取り出す。
#   player:  中山拓哉            … 1人
#   players: [青木保憲, 渡辺翔太] … 複数
#   どちらも無ければクラブカード（選手0人）
def card_player_names(card)
  Array(card["players"] || card["player"]).compact
end

# --- 2. 書き間違いを検証する（DBに触る前に全部チェック）-----------------
errors = []

sets.each do |s|
  errors << "sets: name が未記入の弾があります"          if s["name"].blank?
  errors << "sets: slug が未記入の弾があります（#{s["name"]}）" if s["slug"].blank?
end
dup_set_slugs = set_slugs.tally.select { |_, n| n > 1 }.keys
errors << "sets: slug が重複しています（#{dup_set_slugs.join(", ")}）" if dup_set_slugs.any?

teams.each do |t|
  errors << "teams: name が未記入のチームがあります"       if t["name"].blank?
  errors << "teams: slug が未記入のチームがあります（#{t["name"]}）" if t["slug"].blank?
end
dup_team_slugs = team_slugs.tally.select { |_, n| n > 1 }.keys
errors << "teams: slug が重複しています（#{dup_team_slugs.join(", ")}）" if dup_team_slugs.any?

# 同名の選手が複数いると、seed が同じ1人として扱ってしまい所属が上書きされる。
# 実際には別人か、あるいは移籍データの重複なので、必ず知らせる。
dup_player_names = players.map { |p| p["name"] }.tally.select { |_, n| n > 1 }.keys
if dup_player_names.any?
  errors << "players: 同じ選手名が複数あります（#{dup_player_names.join(", ")}）"
end

# 同じチーム内で背番号が重複していないか
players.group_by { |p| p["team"] }.each do |team_slug, ps|
  nums = ps.map { |p| p["jersey_number"] }.compact
  dups = nums.tally.select { |_, n| n > 1 }.keys
  errors << "#{team_slug}: 背番号が重複しています（#{dups.join(", ")}）" if dups.any?
end

players.each do |p|
  errors << "players: name が未記入の選手があります" if p["name"].blank?
  # 選手の team は、teams に書いた slug を指していなければならない
  if p["team"].blank?
    errors << "#{p["name"]}: team が未記入です"
  elsif !team_slugs.include?(p["team"])
    errors << "#{p["name"]}: チーム \"#{p["team"]}\" は teams にありません"
  end
end

# --- ラインナップ（弾ごとの収録カード）の検証 ---
lineups.each do |lu|
  slug = lu["set"]
  unless set_slugs.include?(slug)
    errors << "lineups: 弾 \"#{slug}\" は sets にありません"
    next
  end

  cards = lu["cards"] || []
  cards.each do |c|
    # 写っている選手。player（1人）でも players（複数）でも書ける。
    # クラブカードはどちらも書かない
    names = card_player_names(c)
    label = names.presence&.join("・") || c["name"] || c["team"]

    names.each do |n|
      unless player_names.include?(n)
        errors << "#{slug}: 選手 \"#{n}\" は players にいません（表記ゆれの可能性）"
      end
    end

    # チームは明記されていればそれを使う。
    # 選手1人なら省略でき、その場合はその選手の所属チームになる
    if c["team"].present? && !team_slugs.include?(c["team"])
      errors << "#{slug}: #{label} のチーム \"#{c["team"]}\" は teams にありません"
    elsif c["team"].blank? && names.size != 1
      errors << "#{slug}: #{label} は選手が#{names.size}人なので team の指定が必要です"
    end

    # 選手が1人でないカードは、表示に使う name が必要
    if names.size != 1 && c["name"].blank?
      errors << "#{slug}: 選手が#{names.size}人のカードには name が必要です（#{label}）"
    end

    r = c["rarity"]
    unless r.is_a?(Integer) && (1..5).cover?(r)
      errors << "#{slug}: #{label} のレア度 \"#{r}\" は 1〜5 の数字で書いてください"
    end
  end

  # 同じ弾の中で、同じ内容のカードが重複していないか
  keys = cards.map { |c| [ card_player_names(c).sort, c["team"], c["name"].to_s ] }
  keys.tally.select { |_, n| n > 1 }.each_key do |k|
    errors << "#{slug}: 同じ内容のカードが複数あります（#{k[0].join("・")} #{k[2]}）"
  end
end

dup_lineup_sets = lineups.map { |lu| lu["set"] }.tally.select { |_, n| n > 1 }.keys
errors << "lineups: 同じ弾が複数あります（#{dup_lineup_sets.join(", ")}）" if dup_lineup_sets.any?

if errors.any?
  warn "seed を中断しました。db/seeds/card_sets.yml を直してください:"
  errors.each { |e| warn "  - #{e}" }
  abort
end

# --- 3. DB に投入する（冪等）-------------------------------------------
ActiveRecord::Base.transaction do
  # カテゴリ「トレード募集」。弾はこの下にぶら下げる（ユーザーには見せない裏方）
  board = Board.find_or_create_by!(slug: "trade") do |b|
    b.name = "トレード募集"
    b.description = "欲しいカード・譲れるカードを書いて、トレード相手を探す場所"
    b.position = 1
  end

  # 弾(Topic)。slug で探して、無ければ作る。あれば名前や説明を更新。
  #
  # YAML はリリース順（古い順）で書く＝新しい弾は末尾に追記するだけでよい。
  # 一方、画面では新しい弾を先に見せたいので、position は逆順に振る。
  # （最後の要素＝最新が position 1 になり、Topic.ordered で先頭に来る）
  topics_by_slug = {}
  sets.each_with_index do |s, i|
    topic = board.topics.find_or_initialize_by(slug: s["slug"])
    topic.name = s["name"]
    topic.description = s["description"]
    topic.position = sets.size - i
    topic.save!
    topics_by_slug[s["slug"]] = topic
  end

  # YAML から消えた弾の後始末。
  # カードや募集が紐づいているものは消さず、警告するだけにする
  # （うっかり YAML から消したときに、データごと失わないため）。
  board.topics.where.not(slug: set_slugs).each do |t|
    if t.cards.exists? || Post.wanting_topic(t).exists?
      warn "注意: 弾「#{t.name}」は YAML にありませんが、" \
           "カードや募集が紐づいているため残します"
    else
      t.destroy!
      puts "YAML から消えた弾を削除しました: #{t.name}"
    end
  end

  # チーム(Team)。slug で探して、無ければ作る
  teams_by_slug = {}
  teams.each_with_index do |t, i|
    team = Team.find_or_initialize_by(slug: t["slug"])
    team.name = t["name"]
    team.position = i + 1
    team.save!
    teams_by_slug[t["slug"]] = team
  end

  # YAML から消えたチームの後始末。選手が所属していれば残す
  Team.where.not(slug: team_slugs).each do |t|
    if t.players.exists?
      warn "注意: チーム「#{t.name}」は YAML にありませんが、" \
           "選手が所属しているため残します"
    else
      t.destroy!
      puts "YAML から消えたチームを削除しました: #{t.name}"
    end
  end

  # 選手(Player)
  players_by_name = {}
  players.each do |p|
    player = Player.find_or_initialize_by(name: p["name"])
    player.team = teams_by_slug.fetch(p["team"])  # slug からチームを引いて紐づける
    player.jersey_number = p["jersey_number"]
    player.position = p["position"]
    player.save!
    players_by_name[p["name"]] = player
  end

  # カード(Card)。弾ごとのラインナップから作る
  lineups.each do |lu|
    topic = topics_by_slug.fetch(lu["set"])
    (lu["cards"] || []).each do |c|
      card_players = card_player_names(c).map { |n| players_by_name.fetch(n) }

      # チームは、書いてあればそれを使う。
      # 省略された場合（選手1人のとき）は、その選手の所属クラブ
      team = if c["team"].present?
               teams_by_slug.fetch(c["team"])
      else
               card_players.first.team
      end

      # 同じ内容のカードが既にあれば使い回す（何度実行しても増えない）
      key = if card_players.any?
              "players:#{card_players.map(&:id).sort.join(',')}:#{c["name"]}"
      else
              "team:#{team.id}:#{c["name"]}"
      end

      card = Card.find_or_initialize_by(topic: topic, key: key)
      card.team = team
      card.name = c["name"].to_s
      card.rarity = c["rarity"]
      card.players = card_players
      card.save!
    end
  end
end

# --- 4. 結果を表示 -----------------------------------------------------
puts "seed 完了: 弾 #{Topic.count} 個 / チーム #{Team.count} 個 / " \
     "選手 #{Player.count} 人 / カード #{Card.count} 枚"
