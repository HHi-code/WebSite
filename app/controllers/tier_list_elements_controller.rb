class TierListElementsController < ApplicationController
  before_action :require_login

  # POST /tier_lists/:tier_list_id/elements
  # Создаёт элемент прямо внутри тирлиста (без перезагрузки страницы).
  def create
    @tier_list = current_user.tier_lists.find(params[:tier_list_id])
    @element = Element.new(element_params)
    @element.tier_list = @tier_list

    ActiveRecord::Base.transaction do
      @element.save!
      @tier_list.tier_list_elements.create!(
        element: @element,
        rank: TierList::UNRANKED,
        position: @tier_list.tier_list_elements.unranked.count
      )
    end

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.append("tier-unranked-zone", partial: "tier_lists/card", locals: { element: @element, show_delete: true }),
          turbo_stream.update("tier-unranked-count", @tier_list.tier_list_elements.unranked.count.to_s)
        ].compact
      end
    end
  rescue ActiveRecord::RecordInvalid
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.update(
          "tier-element-form",
          partial: "tier_lists/element_modal_form",
          locals: { element: @element }
        ), status: :unprocessable_entity
      end
    end
  rescue ActiveRecord::RecordNotFound
    head :not_found
  end

  # DELETE /tier_lists/:tier_list_id/elements/:id
  # Удаляет нераспределённый элемент тирлиста (только свой, только своего тирлиста).
  def destroy
    @tier_list = current_user.tier_lists.find(params[:tier_list_id])

    # Элемент должен быть в нераспределённых этого тирлиста.
    placement = @tier_list.tier_list_elements.unranked.joins(:element).find_by(elements: { id: params[:id] })

    unless placement
      render json: { error: "Элемент не найден в нераспределённых этого тирлиста" }, status: :not_found
      return
    end

    element = placement.element

    # Безопасность: элемент должен принадлежать именно этому тирлисту.
    unless element.tier_list_id == @tier_list.id
      render json: { error: "Нельзя удалить элемент чужого тирлиста" }, status: :forbidden
      return
    end

    ActiveRecord::Base.transaction do
      placement.destroy!
      # Удаляем сам элемент, только если он создан внутри тирлиста и не связан с каталогом.
      element.destroy! if element.tier_list_id == @tier_list.id && element.catalog_id.blank?
    end

    render json: { status: "ok", element_id: element.id }
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Тирлист не найден" }, status: :not_found
  end

  # POST /tier_lists/:tier_list_id/elements/import
  # Импортирует элементы выбранного каталога в тирлист как новые отдельные элементы.
  def import
    @tier_list = current_user.tier_lists.find(params[:tier_list_id])
    @catalog = current_user.catalogs.find(params[:catalog_id])

    imported_elements = []
    count = 0

    ActiveRecord::Base.transaction do
      @catalog.elements.each do |source_element|
        # Защита от дублей: не импортировать элемент с таким названием дважды в один тирлист.
        next if @tier_list.elements.where(title: source_element.title).exists?

        element = Element.create!(title: source_element.title, tier_list: @tier_list)
        @tier_list.tier_list_elements.create!(
          element: element,
          rank: TierList::UNRANKED,
          position: @tier_list.tier_list_elements.unranked.count
        )
        imported_elements << element
        count += 1
      end
    end

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          *imported_elements.map { |element| turbo_stream.append("tier-unranked-zone", partial: "tier_lists/card", locals: { element: element, show_delete: true }) },
          turbo_stream.update("tier-unranked-count", @tier_list.tier_list_elements.unranked.count.to_s),
          turbo_stream.update("tier-save-status", "Импортировано элементов: #{count}")
        ]
      end
    end
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Тирлист или каталог не найден" }, status: :not_found
  end

  private

  def element_params
    params.require(:element).permit(:title, :image)
  end
end
