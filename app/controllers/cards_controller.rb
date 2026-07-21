# 収録カードを全弾まとめて見るページ。
# 弾・クラブ・レア度・キーワードで絞り込める。
class CardsController < ApplicationController
  def index
    # 絞り込みメニューの選択肢
    @topics = Topic.ordered
    @teams  = Team.ordered

    # 選んだ条件を、画面（選択状態の復元）と絞り込みの両方で使う
    @topic_id = params[:topic_id].presence
    @team_id  = params[:team_id].presence
    @rarity   = params[:rarity].presence
    @query    = params[:q].to_s.strip

    cards = Card.includes(:topic, :team, :players)
    cards = cards.where(topic_id: @topic_id) if @topic_id
    cards = cards.where(team_id: @team_id)   if @team_id
    cards = cards.where(rarity: @rarity)     if @rarity

    # カード名だけでなく選手名・チーム名・弾名でも引っかかってほしいので、
    # Card#search_text（それらを繋げた文字列）を使って Ruby 側で絞る。
    # 全部で1000枚に満たない規模なので、これで十分速い。
    cards = cards.to_a
    if @query.present?
      needle = @query.downcase
      cards = cards.select { |c| c.search_text.include?(needle) }
    end

    # 弾（新しい順）→ クラブ順 → レア度の高い順 → 背番号順
    @cards = cards.sort_by { |c| [ c.topic.position, c.team.position, -c.rarity, c.sort_number ] }
    @total = @cards.size

    # 画面では弾ごとに区切って見せる
    @cards_by_topic = @cards.group_by(&:topic)
  end
end
