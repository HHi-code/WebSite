class TierListLayoutsController < ApplicationController
  before_action :require_login

  # PATCH /tier_lists/:tier_list_id/layout
  # Принимает полное распределение: { layout: { "S" => [1, 2], ..., "unranked" => [3] } }
  # Полностью перезаписывает распределение тирлиста в одной транзакции.
  def update
    @tier_list = current_user.tier_lists.find(params[:tier_list_id])

    layout = params[:layout]
    return render_error("Некорректные данные") unless layout.is_a?(ActionController::Parameters)

    # Не доверяем рангам из браузера: разрешены только S..F и «unranked».
    unknown_ranks = layout.keys - TierList::ALL_RANKS
    return render_error("Некорректный ранг") if unknown_ranks.any?

    # Каждый ранг должен приходить списком id.
    layout.each_pair do |_rank, value|
      return render_error("Некорректные данные") unless value.is_a?(Array)
    end

    rows, error = build_rows(layout.permit(TierList::ALL_RANKS.index_with { [] }))
    return render_error(error) if error
    ActiveRecord::Base.transaction do
      @tier_list.tier_list_elements.delete_all
      rows.each { |row| @tier_list.tier_list_elements.create!(row) }
    end

    render json: { status: "ok" }
  rescue ActiveRecord::RecordNotFound
    render_error("Тирлист не найден", status: :not_found)
  rescue ActiveRecord::RecordInvalid => exception
    render_error(exception.record.errors.full_messages.join(", "))
  end

  private

  def build_rows(layout)
    owned_element_ids = current_user.element_ids.index_with(true)
    rows = []
    seen = {}
    counters = Hash.new(0)

    TierList::ALL_RANKS.each do |rank|
      next unless layout.key?(rank)

      element_ids = layout[rank]
      return [nil, "Некорректные данные"] unless element_ids.is_a?(Array)

      element_ids.each do |raw_id|
        element_id = normalize_id(raw_id)
        return [nil, "Некорректный элемент"] if element_id.nil?
        return [nil, "Элемент не найден"] unless owned_element_ids.key?(element_id)
        return [nil, "Элемент указан дважды"] if seen.key?(element_id)

        seen[element_id] = true
        rows << { element_id: element_id, rank: rank, position: counters[rank] }
        counters[rank] += 1
      end
    end

    [rows, nil]
  end

  # Позицию всегда вычисляем на сервере по порядку в массиве — значению из браузера не доверяем.
  def normalize_id(raw)
    case raw
    when Integer then raw
    when String then (Integer(raw, 10) rescue nil)
    end
  end

  def render_error(message, status: :unprocessable_entity)
    render json: { errors: [message] }, status: status
  end
end
