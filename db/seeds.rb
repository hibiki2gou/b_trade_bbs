# ============================================================
# 初期データ投入
#
#     docker compose exec web bin/rails db:seed
#
# db/seeds/card_sets.yml を読み込んで、弾・選手・カードを登録する。
# 何度実行しても同じ結果になる（冪等）。利用者の投稿(Post)には触れない。
# ============================================================

# --- 1. YAML を読み込む ------------------------------------------------
yaml_path = Rails.root.join("db/seeds/card_sets.yml")
data = YAML.load_file(yaml_path)
sets    = data["sets"]    || []
players = data["players"] || []

valid_slugs = sets.map { |s| s["slug"] }

# --- 2. 書き間違いを検証する（DBに触る前に全部チェック）-----------------
errors = []

sets.each do |s|
  errors << "sets: name が未記入の弾があります"        if s["name"].blank?
  errors << "sets: slug が未記入の弾があります（#{s["name"]}）" if s["slug"].blank?
end
dup_slugs = valid_slugs.tally.select { |_, n| n > 1 }.keys
errors << "sets: slug が重複しています（#{dup_slugs.join(", ")}）" if dup_slugs.any?

players.each do |p|
  errors << "players: name が未記入の選手があります" if p["name"].blank?
  errors << "#{p["name"]}: team が未記入です"        if p["team"].blank?

  cards = p["cards"] || []
  cards.each do |c|
    unless valid_slugs.include?(c["set"])
      errors << "#{p["name"]}: 弾 \"#{c["set"]}\" は sets にありません"
    end
    r = c["rarity"]
    unless r.is_a?(Integer) && (1..5).cover?(r)
      errors << "#{p["name"]}: レア度 \"#{r}\" は 1〜5 の数字で書いてください"
    end
  end

  # 同じ弾に複数カードがあるのに name が未記入 / name が重複していないか
  cards.group_by { |c| c["set"] }.each do |slug, cs|
    next if cs.size == 1
    names = cs.map { |c| c["name"] }
    errors << "#{p["name"]}: 弾 \"#{slug}\" に複数カードがあるので name が必要です" if names.any?(&:blank?)
    dups  = names.compact.tally.select { |_, n| n > 1 }.keys
    errors << "#{p["name"]}: 弾 \"#{slug}\" で name が重複しています（#{dups.join(", ")}）" if dups.any?
  end
end

if errors.any?
  warn "seed を中断しました。db/seeds/card_sets.yml を直してください:"
  errors.each { |e| warn "  - #{e}" }
  abort
end

# --- 3. DB に投入する（冪等）-------------------------------------------
ActiveRecord::Base.transaction do
  # カテゴリ「トレード募集」。弾はこの下にぶら下げる
  board = Board.find_or_create_by!(slug: "trade") do |b|
    b.name = "トレード募集"
    b.description = "欲しいカード・譲れるカードを書いて、トレード相手を探す場所"
    b.position = 1
  end

  # 弾(Topic)。slug で探して、無ければ作る。あれば名前や説明を更新
  topics_by_slug = {}
  sets.each_with_index do |s, i|
    topic = board.topics.find_or_initialize_by(slug: s["slug"])
    topic.name = s["name"]
    topic.description = s["description"]
    topic.position = i + 1
    topic.save!
    topics_by_slug[s["slug"]] = topic
  end

  # 選手(Player)とカード(Card)
  players.each do |p|
    player = Player.find_or_initialize_by(name: p["name"])
    player.team = p["team"]
    player.save!

    (p["cards"] || []).each do |c|
      topic = topics_by_slug.fetch(c["set"])
      # カードの identity は 弾×選手×カード名。name 未記入は "" として扱う
      card = Card.find_or_initialize_by(topic: topic, player: player, name: c["name"].to_s)
      card.rarity = c["rarity"]
      card.save!
    end
  end
end

# --- 4. 結果を表示 -----------------------------------------------------
puts "seed 完了: 弾 #{Topic.count} 個 / 選手 #{Player.count} 人 / カード #{Card.count} 枚"
