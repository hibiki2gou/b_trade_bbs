import { Controller } from "@hotwired/stimulus"

// 画面右上の通知（トースト）を、少し経ったら自動で消すコントローラ。
export default class extends Controller {
  connect() {
    // 4秒後に消す。消えるアニメーションのため、まず is-leaving を付ける。
    this.timer = setTimeout(() => {
      this.element.classList.add("is-leaving")
      // アニメーションが終わってから要素を取り除く
      setTimeout(() => this.element.remove(), 300)
    }, 4000)
  }

  // ページを離れるときにタイマーを片付ける（後始末）
  disconnect() {
    clearTimeout(this.timer)
  }
}
