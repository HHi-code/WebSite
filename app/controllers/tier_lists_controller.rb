class TierListsController < ApplicationController
  before_action :require_login

  def index
    @tier_lists = current_user.tier_lists.order(created_at: :desc)
  end

  def show
    @tier_list = current_user.tier_lists.find(params[:id])

    # Ошибки импорта (из модального окна) — инициализируем пустым массивом,
    # иначе в шаблоне модалки импорта будет nil и вызов .any? упадёт.
    @import_errors = []

    # Только элементы, привязанные к этому тирлисту — элементы из каталогов
    # пользователя не добавляются автоматически.
    placements = @tier_list.tier_list_elements.includes(:element).ordered

    @ranked = TierList::RANKS.index_with { [] }
    @unranked = []

    placements.each do |placement|
      if TierList::RANKS.include?(placement.rank)
        @ranked[placement.rank] << placement.element
      else
        @unranked << placement.element
      end
    end

    @total_elements = placements.size
  rescue ActiveRecord::RecordNotFound
    redirect_to tier_lists_path, alert: "Тирлист не найден"
  end

  def create
    @tier_list = current_user.tier_lists.new(tier_list_params)

    if @tier_list.save
      redirect_to tier_lists_path, notice: "Тирлист успешно создан"
    else
      redirect_to tier_lists_path, alert: @tier_list.errors.full_messages.join(", ")
    end
  end

  private

  def tier_list_params
    params.require(:tier_list).permit(:title, :description)
  end
end
