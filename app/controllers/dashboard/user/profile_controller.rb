class Dashboard::User::ProfileController < UserController
  before_action :authorize_user

  # template dashboard/user/profile/index
  def index
    begin
      @user = User.find_by(id: @current_user.id)

      if @user.nil?
        flash[:notice] = "User not found"
        redirect_to '/dashboard/user/home' and return
      end

      @application = ::Application.find(@current_user.application.id)
      @auth_sessions = @user.auth_sessions.order(updated_at: :desc)
      @auth_sessions_total = @auth_sessions.count
      @auth_sessions = @auth_sessions.page(params[:page])
      @chat_rooms = @user.chat_rooms
      @user_roles_id = @user.roles.pluck(:id)

      @path_segments = request.fullpath.split("/")

      render "index"
    rescue => e
      flash[:notice] = e.message
      redirect_to '/dashboard/user/home'
    end
  end

  def update
    begin
      @user = User.find_by(id: @current_user.id, application_id: @current_user.application.id)
      user_params = params.permit!

      # use if clause to update phone_number, fullname, email, gender, date of birth and is public only
      # this will avoid user to update another unpermitted column such as qiscus email or qiscus token
      phone_number = user_params[:phone_number]
      if phone_number.present? && !phone_number.nil? && phone_number != ""
        phone_number = phone_number.strip().delete(' ')
        phone_number = PhonyRails.normalize_number(phone_number, default_country_code: 'ID') # normalize phone number

        # before updating user's email or phone number, check if there are no another user
        # who have same email/phone number except current user
        if User.where.not(id: @user.id).where(application_id: @user.application.id).exists?(phone_number: phone_number)
          raise StandardError.new("Your submitted phone number already used by another user. Please use another phone number.")
        end

        @user.phone_number = phone_number
      end

      # secondary phone number for buddygo support
      secondary_phone_number = user_params[:secondary_phone_number]
      if secondary_phone_number.present? && !secondary_phone_number.nil? && secondary_phone_number != ""
        secondary_phone_number = secondary_phone_number.strip().delete(' ')
        @user.secondary_phone_number = secondary_phone_number
      end

      fullname = user_params[:fullname]
      if fullname.present? && !fullname.nil? && fullname != ""
        @user.fullname = (fullname.nil? || fullname == "") ? "" : fullname.strip().gsub(/\s+/, " ") # to remove multi space to single space
      end

      email = user_params[:email]
      if email.present? && !email.nil? && email != ""
        # before updating user's email or phone number, check if there are no another user
        # who have same email/phone number except current user
        if User.where.not(id: @user.id).where(application_id: @user.application.id).exists?(email: email)
          raise StandardError.new("Your submitted email already used by another user. Please use another email.")
        end

        @user.email = (email.nil? || email == "") ? "" : email.strip().delete(' ')
      end

      gender = user_params[:gender]
      if gender.present? && !gender.nil? && gender != ""
        @user.gender = gender
      end

      date_of_birth = user_params[:date_of_birth]
      if date_of_birth.present? && !date_of_birth.nil? && date_of_birth != ""
        @user.date_of_birth = date_of_birth
      end

      is_public = user_params[:is_public]
      if is_public.present?
        if is_public == "on"
          @user.is_public = true
        else

          @user.is_public = false
        end
      end

      description = user_params[:description]
      if description.present? && !description.nil? && description != ""
        @user.description = description
      end

      callback_url = user_params[:callback_url]
      @user.callback_url = callback_url

      @avatar_file = params[:avatar_file]
      if @avatar_file.present?
        qiscus_sdk = QiscusSdk.new(@user.application.app_id, @user.application.qiscus_sdk_secret)
        url = qiscus_sdk.upload_file(@user.qiscus_token, @avatar_file)
        @user.avatar_url = url
      end

      @user.save!
      auto_responder_exist = user_params.has_key?(:auto_responder)
      auto_starter_exist =  user_params.has_key?(:auto_starter)
      if auto_starter_exist
        auto_starter = user_params[:auto_starter]
        UserAdditionalInfo.create_or_update_user_additional_info(
          [@user.id],
          UserAdditionalInfo::AUTO_STARTER_KEY,
          auto_starter
          )
      end

      if auto_responder_exist
        auto_responder = user_params[:auto_responder]
        UserAdditionalInfo.create_or_update_user_additional_info(
        [@user.id],
        UserAdditionalInfo::AUTO_RESPONDER_KEY,
        auto_responder
        )
      end

      # Update SDK Profile if fullname or avatar_file present
      if fullname.present? || @avatar_file.present?
        user = User.find_by(id: @current_user.id, application_id: @current_user.application.id)
        qiscus_sdk = QiscusSdk.new(user.application.app_id, user.application.qiscus_sdk_secret)
        qiscus_token = qiscus_sdk.update_profile(user.qiscus_email, user.fullname, user.avatar_url)
      end

      flash[:success] = "Success update profile."
      redirect_back fallback_location: '/dashboard/user/profile' and return
    rescue => e
      render json: {
        backtrace: e.backtrace
      } and return
      flash[:notice] = e.message
      redirect_back fallback_location: '/dashboard/user/home'
    end
  end

  def activity
    begin
      @user = User.find_by(id: @current_user.id)

      if @user.nil?
        flash[:notice] = "User not found"
        redirect_to '/dashboard/user/home' and return
      end

      @application = ::Application.find(@current_user.application.id)
      @auth_sessions = @user.auth_sessions.order(updated_at: :desc)
      @auth_sessions = @auth_sessions.page(params[:page])
      @chat_rooms = @user.chat_rooms.order(updated_at: :desc)
      @user_roles_id = @user.roles.pluck(:id)

      @path_segments = request.fullpath.split("/")

      render "activity"
      # render json: {
      #   user: @chat_rooms
      # }
    rescue => e
      flash[:notice] = e.message
      redirect_to '/dashboard/user/home'
    end
  end

end