class PagesController < ApplicationController
  def home
    @catalogs = current_user.catalogs.order(created_at: :desc) if logged_in?
  end

  def styleguide
  end
end
