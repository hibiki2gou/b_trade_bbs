module ApplicationHelper
  # 弾やチームのサムネイル画像を出す。
  # record.image_path（例: sets/record.jpg）に画像があれば <img> を、
  # 無ければ名前を大きく見せるタイル（プレースホルダー）を表示する。
  # → 画像を app/assets/images/ に置けば、自動で画像表示に切り替わる。
  def board_thumbnail(record)
    file = Rails.root.join("app/assets/images", record.image_path)
    if File.exist?(file)
      image_tag record.image_path, alt: record.name, class: "thumb__img"
    else
      content_tag :div, record.name, class: "thumb__placeholder"
    end
  end

  # レア度の数字(1〜5)を ★ で表す。card.stars と同じだが、
  # ビューから rarity 数値を直接渡したいとき用。
  def rarity_stars(rarity)
    content_tag :span, "★" * rarity + "☆" * (5 - rarity), class: "stars"
  end
end
