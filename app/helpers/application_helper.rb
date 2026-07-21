module ApplicationHelper
  # 弾やチームのサムネイル画像を出す。
  # record.image_path（例: sets/record.jpg）に画像があれば <img> を、
  # 無ければ名前を大きく見せるタイル（プレースホルダー）を表示する。
  # → 画像を app/assets/images/ に置けば、自動で画像表示に切り替わる。
  def board_thumbnail(record)
    image_tag record.image_path, alt: record.name, class: "thumb__img"
  rescue Propshaft::MissingAssetError
    # ここに来る理由は2つある。
    #   ① 本当に画像を置いていない → 名前タイルを出す（正常）
    #   ② 置いてあるのに Propshaft が見つけられない
    # ②は Propshaft のファイル一覧が古いときに起きる。一覧の更新判定は
    # ActiveSupport::FileUpdateChecker#updated? が「ファイル数が変わったか」
    # または「最新 mtime が進んだか」で行う。つまり画像を1枚消して1枚足すなど、
    # 数が変わらず mtime も古いままだと、追加に気づけない。
    # ディスクに実体があるなら一覧を作り直して、もう一度だけ試す。
    if refresh_assets_and_found?(record.image_path)
      image_tag record.image_path, alt: record.name, class: "thumb__img"
    else
      content_tag :div, record.name, class: "thumb__placeholder"
    end
  end

  # ヘッダーのロゴ。app/assets/images/logo.png があれば画像を、
  # 無ければサイト名のテキストを出す（画像を置く前でも表示が崩れない）。
  def board_thumbnail_logo
    image_tag "logo.png", alt: "TRADE COURT", class: "site-header__logo-img"
  rescue Propshaft::MissingAssetError
    content_tag :span, "TRADE COURT", class: "site-header__logo-text"
  end

  # Propshaft のファイル一覧を作り直し、その画像が見つかるようになったか返す。
  # 本番はアセットを事前ビルドしていて作り直せないので、開発時だけ動かす。
  def refresh_assets_and_found?(logical_path)
    return false unless Rails.application.config.assets.sweep_cache

    load_path = Rails.application.assets.load_path
    # execute は「更新されていれば」ではなく無条件にキャッシュを作り直す。
    load_path.cache_sweeper.execute
    load_path.find(logical_path).present?
  end

  # レア度の数字(1〜5)を ★ で表す。card.stars と同じだが、
  # ビューから rarity 数値を直接渡したいとき用。
  def rarity_stars(rarity)
    content_tag :span, "★" * rarity + "☆" * (5 - rarity), class: "stars"
  end
end
