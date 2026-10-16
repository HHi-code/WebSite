class CatalogsController < ApplicationController
  before_action :require_login

  def show
    @catalog = current_user.catalogs.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: "Каталог не найден"
  end

  def create
    @catalog = current_user.catalogs.new(catalog_params)

    if @catalog.save
      redirect_to root_path, notice: "Каталог успешно создан"
    else
      respond_to do |format|
        format.html { redirect_to root_path, alert: @catalog.errors.full_messages.join(", ") }
        format.turbo_stream { render :create_error }
      end
    end
  end

  private

  def catalog_params
    params.require(:catalog).permit(:name, :description, :border_color)
  end
end
