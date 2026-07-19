import { Controller } from "@hotwired/stimulus"

// カードを「名前で検索して選ぶ」ための動きを担当するコントローラ。
// 「欲しいカード」でも「出せるカード」でも使い回せる（送信名を name で切り替える）。
export default class extends Controller {
  // HTML 側の目印。data-card-picker-target="query" などと対応する。
  static targets = ["query", "results", "chips"]
  // HTML から渡されるデータ。
  //   cards … カードの一覧（id・ラベル・検索用テキスト）
  //   name  … 送信するときの input の名前（例: post[wanted_card_ids][]）
  static values = { cards: Array, name: String }

  // このコントローラが動き始めたとき最初に1回だけ走る。
  connect() {
    this.selected = new Set()  // すでに選んだカードの id を覚えておく入れ物
  }

  // 入力欄に文字が打たれるたびに呼ばれる。候補を絞り込む。
  filter() {
    const q = this.queryTarget.value.trim().toLowerCase()
    if (q === "") { this.hideResults(); return }

    const matches = this.cardsValue
      .filter(c => !this.selected.has(c.id) && c.search.includes(q))
      .slice(0, 10)  // 多すぎないよう先頭10件まで
    this.renderResults(matches)
  }

  // 絞り込んだ候補を、クリックできるリストとして画面に出す。
  renderResults(matches) {
    this.resultsTarget.innerHTML = ""
    if (matches.length === 0) { this.hideResults(); return }

    matches.forEach(c => {
      const li = document.createElement("li")
      li.textContent = c.label
      li.className = "picker__item"
      li.dataset.action = "click->card-picker#choose"
      li.dataset.id = c.id
      li.dataset.label = c.label
      this.resultsTarget.appendChild(li)
    })
    this.resultsTarget.hidden = false
  }

  // 候補をクリックしたとき。選択済みにして、タグを追加する。
  choose(event) {
    const id = Number(event.currentTarget.dataset.id)
    const label = event.currentTarget.dataset.label
    this.selected.add(id)
    this.addChip(id, label)
    this.queryTarget.value = ""
    this.hideResults()
  }

  // 選んだカードを「タグ（chip）」として表示する。
  // 中に hidden の input を入れて、フォーム送信時に id が送られるようにする。
  addChip(id, label) {
    const chip = document.createElement("span")
    chip.className = "chip"

    const text = document.createElement("span")
    text.textContent = label

    // これがサーバーに送られる本体。名前は HTML から渡された name を使う
    // （欲しい: post[wanted_card_ids][] / 出せる: post[offered_card_ids][]）。
    const hidden = document.createElement("input")
    hidden.type = "hidden"
    hidden.name = this.nameValue
    hidden.value = id

    const remove = document.createElement("button")
    remove.type = "button"
    remove.textContent = "✕"
    remove.className = "chip__remove"
    remove.dataset.action = "click->card-picker#remove"
    remove.dataset.id = id

    chip.append(text, hidden, remove)
    this.chipsTarget.appendChild(chip)
  }

  // タグの✕を押したとき。選択を解除して、タグを消す。
  remove(event) {
    const id = Number(event.currentTarget.dataset.id)
    this.selected.delete(id)
    event.currentTarget.closest(".chip").remove()
  }

  hideResults() {
    this.resultsTarget.hidden = true
  }
}