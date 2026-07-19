module ApplicationHelper
  # 弾やチームのサムネイル画像を出す。
  # record.image_path（例: sets/record.jpg）に画像があれば <img> を、
  # 無ければ名前を大きく見せるタイル（プレースホルダー）を表示する。
  # → 画像を app/assets/images/ に置けば、自動で画像表示に切り替わる。
  def board_thumbnail(record)
    # 画像が無い場合はもちろん、アセットとして解決できない場合も
    # エラーにせず名前タイルを出す。
    # （Propshaft は起動時にファイル一覧を読むため、アプリを動かしたまま
    #   画像を足すと File.exist? が true でも解決に失敗することがある。
    #   1枚のためにページ全体を落とさないよう、ここで受け止める）
    image_tag record.image_path, alt: record.name, class: "thumb__img"
  rescue Propshaft::MissingAssetError
    content_tag :div, record.name, class: "thumb__placeholder"
  end

  # ヘッダーのロゴ。app/assets/images/logo.png があれば画像を、
  # 無ければサイト名のテキストを出す（画像を置く前でも表示が崩れない）。
  def board_thumbnail_logo
    image_tag "logo.png", alt: "TRADE COURT", class: "site-header__logo-img"
  rescue Propshaft::MissingAssetError
    content_tag :span, "TRADE COURT", class: "site-header__logo-text"
  end

  # レア度の数字(1〜5)を ★ で表す。card.stars と同じだが、
  # ビューから rarity 数値を直接渡したいとき用。
  def rarity_stars(rarity)
    content_tag :span, "★" * rarity + "☆" * (5 - rarity), class: "stars"
  end
end
