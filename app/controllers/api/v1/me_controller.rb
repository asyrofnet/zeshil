class Api::V1::MeController < ProtectedController
  before_action :authorize_user
  before_action :ensure_update_profile_params, only: [:update_profile]
  before_action :ensure_update_avatar_params, only: [:update_avatar]

  # =begin
  # @apiVersion 1.0.0
  # @api {get} /api/v1/me My Profile
  # @apiName Me
  # @apiGroup Profile
  #
  # @apiParam {String} access_token User access token
  # =end
  def index
    render json: {
      data: @current_user.as_json({:show_profile => true})
    }
  end

  # =begin
  # @apiVersion 1.0.0
  # @api {post} /api/v1/me/update_profile Update Profile
  # @apiName UpdateProfile
  # @apiGroup Profile
  #
  # @apiDescription Before updating user's email or phone number, system will check whether there are no another user who have same email/phone number except current user. Why this should be considered? For example there are 2 user: A and B registered in same application (id). A register using phone number, let say 123. B register using email, let say b@mail.com.
  #
  # Now, image if we don't check anything about data existense and let A to update his profile email to b@mail.com and let B to update their phone number to 123 (actually it can't be done because of db validation). It will be result strange behaviour in login method, since it just using one parameter, either email or phone number.
  #
  # Now, A have: 123, b@mail.com and B have: 123, b@mail.com It's the same data, and please forget about how it can be B know A's phone number or how it can A know B's email? The point is, it will led system have duplicate data (even it can't be done because of database validation). As we expected, when B try to login he will get authentication using id A. And when A try to login it will be A.
  #
  # @apiParam {String} access_token User access token
  # @apiParam {String} user[fullname] Minimum 4 char maximum 20 char (as mentioned in specification [https://quip.com/EafhASIYmym3](https://quip.com/EafhASIYmym3))
  # @apiParam {String} user[email] Valid email
  # @apiParam {String} user[gender] `male` or `female`
  # @apiParam {String} user[date_of_birth] Date of birth, format `yyyy-mm-dd`
  # @apiParam {Boolean} user[is_public] Profile information is public or not
  # @apiParam {Text} user[description] Profile description (this is a profile status)
  # @apiParam {Text} user[country_name] Country (this is for buddygo support)
  # @apiParam {Text} user[secondary_phone_number] Secondary phone number (this is for buddygo support)
  # @apiParam {Text} user[additional_infos][key] You can fill anything in [key]
  # =end
  def update_profile
    begin
      user = @current_user
      application = user.application
      user_params = params[:user].permit!
      additional_infos = nil

      ActiveRecord::Base.transaction do

      # use if clause to update phone_number, fullname, email, gender, date of birth and is public only
      # this will avoid user to update another unpermitted column such as qiscus email or qiscus token
      phone_number = user_params[:phone_number]
      if phone_number.present? && !phone_number.nil? && phone_number != ""
        phone_number = phone_number.strip().delete(' ')
        # phone_number = PhonyRails.normalize_number(phone_number, default_country_code: 'ID') # normalize phone number

        # before updating user's email or phone number, check if there are no another user
        # who have same email/phone number except current user
        if User.where.not(id: user.id).where(application_id: @current_user.application.id).exists?(phone_number: phone_number)
          raise InputError.new("Your submitted phone number already used by another user. Please use another phone number.")
        end

        user.phone_number = phone_number
      end

      fullname = user_params[:fullname]
      if fullname.present? && !fullname.nil? && fullname != ""
        user.fullname = (fullname.nil? || fullname == "") ? "" : fullname.strip().gsub(/\s+/, " ") # to remove multi space to single space

        # Change username in SDK
        qiscus_sdk = QiscusSdk.new(application.app_id, application.qiscus_sdk_secret)
        qiscus_token = qiscus_sdk.update_profile(user.qiscus_email, fullname)
      else
        raise InputError.new("Fullname minimum character is 4.")
      end

      email = user_params[:email]
      if email.present? && !email.nil? && email != ""
        # before updating user's email or phone number, check if there are no another user
        # who have same email/phone number except current user
        if User.where.not(id: user.id).where(application_id: @current_user.application.id).exists?(email: email)
          raise InputError.new("Your submitted email already used by another user. Please use another email.")
        end

        user.email = (email.nil? || email == "") ? "" : email.strip().delete(' ')
      end

      gender = user_params[:gender]
      if gender.present? && !gender.nil? && gender != ""
        user.gender = gender
      end

      date_of_birth = user_params[:date_of_birth]
      if date_of_birth.present? && !date_of_birth.nil? && date_of_birth != ""
        user.date_of_birth = date_of_birth
      end

      is_public = user_params[:is_public]
      if is_public.present? && !is_public.nil? && is_public != ""
        user.is_public = (is_public.nil? || is_public == "" || is_public != "true") ? false : is_public
      end

      description = user_params[:description]
      if description.present? && !description.nil? && description != ""
        user.description = description
      end

      country_name = user_params[:country_name]
      if country_name.present? && !country_name.nil? && country_name != ""
        user.country_name = country_name
      end

      secondary_phone_number = user_params[:secondary_phone_number]
      if secondary_phone_number.present? && !secondary_phone_number.nil? && secondary_phone_number != ""
        user.secondary_phone_number = secondary_phone_number
      end

      user.save!

      additional_infos = user_params[:additional_infos]

      # Save or update user additional infos
      if !additional_infos.nil?
        new_additional_infos = Array.new
        additional_infos.each do |key, value|
          info = UserAdditionalInfo.find_by(user_id: user.id, key: key)

          if info.nil?
            # if additional info with spesific key doesn't exist then create it
            new_additional_infos.push({:user_id => user.id, :key => key, :value => value})
          elsif info.value != value
            # if additional info with spesific key exist but with different value then update it
            info.update_attributes(:value => value)
          end
        end

        # add new additional infos
        UserAdditionalInfo.create(new_additional_infos)
      end

    end

    render json: {
      data: user.as_json({:show_profile => true})
    }

  rescue ActiveRecord::RecordInvalid => e
    msg = ""
    e.record.errors.map do |k, v|
      key = k.to_s.humanize
      msg = msg + "#{key} #{v}, "
    end

    msg = msg.chomp(", ") + "."
    render json: {
      error: {
        message: msg
      }
      }, status: 422 and return

    rescue => e
      render json: {
        error: {
          message: e.message
        }
        }, status: 422 and return
      end
    end

  # =begin
  # @apiVersion 1.0.0
  # @api {post} /api/v1/me/update_avatar Update Profile Avatar
  # @apiName UpdateAvatarProfile
  # @apiGroup Profile
  #
  # @apiParam {String} access_token User access token
  # @apiParam {File} avatar_file Image file
  # =end
  def update_avatar
    begin
      ActiveRecord::Base.transaction do
        qiscus_sdk = QiscusSdk.new(@current_user.application.app_id, @current_user.application.qiscus_sdk_secret)
        url = qiscus_sdk.upload_file(@current_user.qiscus_token, @avatar_file) # upload file
        @current_user.update!(avatar_url: url) # update avatar_url in qisme

        # Change avatar_url in SDK
        qiscus_sdk.update_profile(@current_user.qiscus_email, nil, url)
      end
      render json: {
        data: @current_user.as_json({:show_profile => true})
      }

    rescue ActiveRecord::RecordInvalid => e
      msg = ""
      e.record.errors.map do |k, v|
        key = k.to_s.humanize
        msg = msg + "#{key} #{v}, "
      end

      msg = msg.chomp(", ") + "."
      render json: {
        error: {
          message: msg
        }
        }, status: 422 and return

      rescue => e
        render json: {
          error: {
            message: e.message
          }
          }, status: 422 and return
        end
      end

  # =begin
  # @apiVersion 1.0.0
  # @api {post} /api/v1/me/logout Logout session
  # @apiDescription This endpoint to ensure there are not trash data in auth_sessions table,
  # since all jwt token are now saved in database, it better to delete it manually
  #
  # @apiName LogoutSession
  # @apiGroup Profile
  #
  # @apiParam {String} access_token User access token
  # @apiParam {String} devicetoken Device token
  # =end
  def logout
    begin
      devicetoken = params[:devicetoken]

      if !devicetoken.present?
        raise InputError.new("User device token must be present.")
      end

      session = AuthSession.find_by(jwt_token: @current_jwt_token, user_id: @current_user.id)

      if !session.nil?
        session.destroy
      end

      userdevicetoken = UserDeviceToken.find_by(devicetoken: devicetoken, user_id: @current_user.id)

      if !userdevicetoken.nil?
        userdevicetoken.destroy
      end

      render json: {
        data: {
          message: 'Logout success.'
        }
      }

    rescue ActiveRecord::RecordInvalid => e
      msg = ""
      e.record.errors.map do |k, v|
        key = k.to_s.humanize
        msg = msg + "#{key} #{v}, "
      end

      msg = msg.chomp(", ") + "."
      render json: {
        error: {
          message: msg
        }
        }, status: 422 and return

      rescue => e
        render json: {
          error: {
            message: e.message
          }
          }, status: 422 and return
        end
      end

  # =begin
  # @apiVersion 1.0.0
  # @api {get} /api/v1/me/features My Active Features
  # @apiName My Active Features
  # @apiGroup Profile
  #
  # @apiParam {String} access_token User access token
  # =end
  def features
    user = @current_user
    user_features = user.features.pluck(:feature_id)

    # Looking for features that have been rolled out to production
    features = Feature.where(application_id: user.application_id)
    features = features.where(is_rolled_out: true).pluck(:feature_id)

    user_features = features + user_features

    user_features = user_features.uniq

    render json: {
      status: 'success',
      data: {
        features: user_features
      }
    }, status: 200
  end

  # =begin
  # @apiVersion 1.0.0
  # @api {post} /api/v1/me/register_device_token Register Device Token
  # @apiName Register Device Token
  # @apiGroup Profile
  #
  # @apiParam {String} access_token User access token
  # @apiParam {String} devicetoken Device token
  # @apiParam {String} user_type Device platform : 'android' or 'ios'
  # =end
  def register_device_token
    begin
      if params[:user_type].nil? || !params[:user_type].present? || params[:user_type] == ""
        raise InputError.new("User type can't be empty.")
      else
        if params[:user_type].downcase.delete(' ') != "android" && params[:user_type].downcase.delete(' ') != "ios"
          raise InputError.new("Permitted user_type is 'android' or 'ios'.")
        end
      end

      if params[:devicetoken].nil? || !params[:devicetoken].present? || params[:devicetoken] == ""
        raise InputError.new("Device token can't be empty. Your user_type is #{params[:user_type]}")
      end

      userdevicetoken = UserDeviceToken.find_by(devicetoken: params[:devicetoken])

      if userdevicetoken.nil?
        userdevicetoken = UserDeviceToken.new
        userdevicetoken.devicetoken = params[:devicetoken]
        userdevicetoken.user_type = params[:user_type]
        userdevicetoken.user_id = @current_user.id

        save_status = true if userdevicetoken.save
      else
        # if devicetoken is exist but with different user_id then update it with current user_id
        if userdevicetoken.user_id != @current_user.id
          userdevicetoken.update_attribute(:user_id, @current_user.id)
          save_status = true
        else
          # do nothing, because devicetoken already exist
          save_status = false
        end
      end

      if save_status
        render :json => {
          status: "success"
        }, status: 200
      else
        render :json => {
          status: "already exists"
        }, status: 200
      end

    rescue => e
      render json: {
        error: {
          message: e.message
        }
      }, status: 422 and return
    end
  end

  # =begin
  # @apiVersion 1.0.0
  # @api {post} /api/v1/me/delete_device_token Delete Device Token
  # @apiName Delete Device Token
  # @apiGroup Profile
  #
  # @apiParam {String} access_token User access token
  # @apiParam {String} devicetoken Device token
  # =end
  def delete_device_token
    begin
      if params[:devicetoken].nil? || !params[:devicetoken].present? || params[:devicetoken] == ""
        raise InputError.new("Please specify your device token.")
      end

      userdevicetoken = UserDeviceToken.find_by(devicetoken: params[:devicetoken], user_id: @current_user.id)

      if !userdevicetoken.nil?
        userdevicetoken.destroy
      else
        raise InputError.new("User device token is not found.")
      end

      render json: {
        status: 'success',
        data: {
          devicetoken: userdevicetoken
        }
      }, status: 200

    rescue => e
      render json: {
        error: {
          message: e.message
        }
      }, status: 422 and return
    end
  end

  # =begin
  # @apiVersion 1.0.0
  # @api {post} /api/v1/me/identity_token Get Identity Token
  # @apiName Get Identity Token
  # @apiGroup Profile
  #
  # @apiParam {String} access_token User access token
  # @apiParam {String} nonce Nonce from SDK
  # =end
  def identity_token
    begin
      nonce = params[:nonce]
      if nonce.nil? || !nonce.present? || nonce == ""
        raise InputError.new("Nonce can't be empty.")
      end

      user = @current_user
      application = user.application

      email_sdk = user.qiscus_email
      username = user.fullname
      if username.nil?
        username = params[:user][:phone_number]
      end
      avatar_url = user.avatar_url

      payload = {
        "iss": application.app_id, # your qiscus app id, can obtained from dashboard
        "iat": Time.now.to_i, # current timestamp in unix
        "exp": (Time.now + 2*60).to_i, # An arbitrary time in the future when this token should expire. In epoch/unix time. We encourage you to limit 2 minutes
        "nbf": Time.now.to_i, # current timestamp in unix
        "nce": nonce, # nonce string from nonce API
        "prn": email_sdk, # your user identity such as email
        "name": "", # optional, string for user name
        "avatar_url": "" # optional, string url of user avatar
      }

      header = {
        "alg": "HS256",
        "typ": "JWT",
        "ver": "v2"
      }

      # generate identity_token using nonce
      identity_token = JWT.encode(payload, application.qiscus_sdk_secret, 'HS256', header)

      render json: {
        data: {
          identity_token: identity_token
        }
      } and return

    rescue => e
      render json: {
        error: {
          message: e.message
        }
      }, status: 422 and return
    end
  end

      private
      def ensure_update_profile_params
        params.require(:user).permit(:fullname, :email, :gender, :date_of_birth, :is_public, :description)
      end

      def ensure_update_avatar_params
        @avatar_file = params[:avatar_file]

        render json: {
          status: 'fail',
          message: 'invalid avatar file'
          }, status: 422 unless @avatar_file
        end

      end