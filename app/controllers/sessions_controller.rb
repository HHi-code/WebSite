class SessionsController < ApplicationController
  def new
  end

  def create
    user = User.find_by(email: params[:email].to_s.strip.downcase)

    if user&.authenticate(params[:password])
      session[:user_id] = user.id
      flash[:notice] = "Вы вошли в систему"
      redirect_to root_path
    else
      flash.now[:alert] = "Неверный email или пароль"
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    session[:user_id] = nil
    flash[:notice] = "Вы вышли из системы"
    redirect_to root_path
  end
end
