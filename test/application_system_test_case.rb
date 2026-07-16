require "test_helper"

# システムテスト（ブラウザを実際に動かすテスト）の共通設定。
# headless_chrome = 画面を表示せずに Chrome を動かすモード（CI 向け）。
class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1400 ]
end
