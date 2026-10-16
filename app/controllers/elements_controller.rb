class ElementsController < ApplicationController
  before_action :require_login

  def show
    @catalog = current_user.catalogs.find(params[:catalog_id])
    @element = @catalog.elements.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: "Элемент не найден"
  end

  def create
    @catalog = current_user.catalogs.find(params[:catalog_id])
    @element = @catalog.elements.new(element_params)

    if @element.save
      redirect_to catalog_path(@catalog), notice: "Элемент успешно создан"
    else
      redirect_to catalog_path(@catalog), alert: @element.errors.full_messages.join(", ")
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: "Каталог не найден"
  end

  private

  def element_params
    params.require(:element).permit(:title, :description, :rating)
  end
end
