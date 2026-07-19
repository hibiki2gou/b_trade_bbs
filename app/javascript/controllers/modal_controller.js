import { Controller } from "@hotwired/stimulus"

// モーダル（画面中央に重なる窓）の開閉を担当するコントローラ。
// HTML標準の <dialog> を使うので、背景を暗くする・Escキーで閉じるは
// ブラウザがやってくれる。
export default class extends Controller {
  static targets = ["dialog"]
  // openValue が true なら、最初から開いた状態にする
  // （投稿に失敗したとき、エラー付きで開き直すために使う）
  static values = { open: Boolean }

  connect() {
    if (this.openValue) this.open()
  }

  open() {
    this.dialogTarget.showModal()
  }

  close() {
    this.dialogTarget.close()
  }

  // 背景（dialog の余白部分）をクリックしたら閉じる。
  // 中身をクリックしたときは閉じないよう、クリック位置で判定する。
  closeOnBackdrop(event) {
    if (event.target === this.dialogTarget) this.close()
  }
}
