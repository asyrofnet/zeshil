class Dashboard::User::AuthController < ApplicationController

  def index
    @application = Application.find_by(app_id: params[:app_id])

    if @application.nil?
      render html: '<h2>Invalid app or nil app</h2>'.html_safe
    else
      render 'login', layout: false and return
    end
    
  end

  def create
    begin
      app_id = params[:app_id]
      username = params[:username]
      passcode = params[:passcode]
      @application = Application.all

      application = Application.find_by(app_id: app_id)

      if application.nil?
        flash[:notice] = "Application id is not found."
        redirect_back fallback_location: "/app/#{app_id}"
      end

      phone_number = username.strip().delete(' ')
      # phone_number = PhonyRails.normalize_number(phone_number, default_country_code: 'ID')
      user = User.find_by(phone_number: phone_number,
          passcode: passcode, application_id: application.id)

      if !user.nil?
        # update passcode to nil (so user can't verify again once the code is used)
        user.update_attribute(:passcode, nil)
        # create session
        session[:user_id] = user.id

        redirect_to '/dashboard/user/home' and return
      else
        flash[:notice] = "Can't find user or wrong passcode."
        redirect_back fallback_location: "/app/#{app_id}"
      end

    rescue => e
      flash[:notice] = e.message
      redirect_back fallback_location: "/app/#{app_id}"
    end
  end

  def logout
    # Get app_id
    user = User.find(session[:user_id])
    application = Application.find(user.application_id) 
    app_id = application.app_id

    # reset_session
    session.delete(:user_id)
    redirect_to "/app/#{app_id}"
  end

end