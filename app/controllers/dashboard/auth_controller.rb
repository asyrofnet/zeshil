class Dashboard::AuthController < ApplicationController

  def index
    if !session[:superuser].nil?
      redirect_to '/dashboard/super_admin/home' and return
    else 
      @application = Application.all
      render 'login', layout: false and return
    end
  end

  def create
    begin
      app_id = params[:app_id]
      username = params[:username]
      passcode = params[:passcode]
      @application = Application.all

      # if super admin
      if app_id == 'super'
        if username == ENV['SUPER_ADMIN_USERNAME'] && passcode == ENV['SUPER_ADMIN_PASSWORD']
          session[:superuser] = 'super'
          redirect_to '/dashboard/super_admin/home' and return
        else
          flash[:notice] = "Wrong username or password."
          redirect_back fallback_location: "superadmin"
        end
      end

    rescue Exception => e
      flash[:notice] = e.message
      redirect_back fallback_location: "superadmin"
    end
  end

  def logout
    # reset_session
    session.delete(:superuser)
    redirect_to superadmin_path and return
  end

end