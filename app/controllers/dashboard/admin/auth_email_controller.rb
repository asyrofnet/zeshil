class Dashboard::Admin::AuthEmailController < ApplicationController

  def index
    @application = ::Application.find_by(app_id: params[:app_id])

    if @application.nil?
      render html: '<h2>Invalid app or nil app</h2>'.html_safe
    else
      render 'login', layout: false and return
    end

  end

  def create
    begin
      app_id = params[:app_id]
      email = params[:email]
      passcode = params[:passcode]
      @application = ::Application.all

      application = ::Application.find_by(app_id: app_id)

      if application.nil?
        flash[:notice] = "Application id is not found."
        redirect_back fallback_location: "/app/#{app_id}/auth_email"
      end

      # phone_number = username.strip().delete(' ')
      # phone_number = PhonyRails.normalize_number(phone_number, default_country_code: 'ID')
      user = ::User.find_by(email: email,
          passcode: passcode, application_id: application.id)

      if !user.nil? && user.is_admin
        # update passcode to nil (so user can't verify again once the code is used)
        user.update_attribute(:passcode, nil)
        # create session
        session[:current_user_id] = user.id

        redirect_to '/dashboard/admin/home' and return
      else
        flash[:notice] = "User is not an admin."
        redirect_back fallback_location: "/app/#{app_id}/auth_email"
      end

    rescue Exception => e
      flash[:notice] = e.message
      redirect_back fallback_location: "/app/#{app_id}"
    end
  end

end
