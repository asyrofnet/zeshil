require 'jwt'

class Api::V1::Rest::MeController < ApplicationController

  # =begin
  # @apiVersion 1.0.0
  # @api {post} /api/v1/rest/me/update_profile Update Profile
  # @apiName UpdateProfile
  # @apiGroup Rest API
  #
  # @apiDescription Before updating user's email or phone number, system will check whether there are no another user who have same email/phone number except current user. Why this should be considered? For example there are 2 user: A and B registered in same application (id). A register using phone number, let say 123. B register using email, let say b@mail.com.
  #
  # Now, image if we don't check anything about data existense and let A to update his profile email to b@mail.com and let B to update their phone number to 123 (actually it can't be done because of db validation). It will be result strange behaviour in login method, since it just using one parameter, either email or phone number.
  #
  # Now, A have: 123, b@mail.com and B have: 123, b@mail.com It's the same data, and please forget about how it can be B know A's phone number or how it can A know B's email? The point is, it will led system have duplicate data (even it can't be done because of database validation). As we expected, when B try to login he will get authentication using id A. And when A try to login it will be A.
  #
  # @apiParam {String} server_key Application server key
  # @apiParam {String} app_id Application app_id
  # @apiParam {String} user[id] User id
  # @apiParam {String} user[fullname] Minimum 4 char maximum 20 char (as mentioned in specification [https://quip.com/EafhASIYmym3](https://quip.com/EafhASIYmym3))
  # @apiParam {String} user[email] Valid email
  # @apiParam {String} user[gender] `male` or `female`
  # @apiParam {String} user[date_of_birth] Date of birth, format `yyyy-mm-dd`
  # @apiParam {String} user[avatar_url] Avatar url
  # @apiParam {Boolean} user[is_public] Profile information is public or not
  # @apiParam {Text} user[description] Profile description (this is a profile status)
  # @apiParam {Text} user[country_name] Country (this is for buddygo support)
  # @apiParam {Text} user[secondary_phone_number] Secondary phone number (this is for buddygo support)
  # @apiParam {Text} user[additional_infos][key] You can fill anything in [key]
  # =end
  def update_profile
    begin
      application = nil
      additional_infos = nil
      user = nil

      ActiveRecord::Base.transaction do

        app_id = params[:app_id]
        if app_id.nil? || app_id == ""
          raise InputError.new('app_id cant be empty')
        end

        server_key = params[:server_key]
        if server_key.nil? || server_key == ""
          raise InputError.new('server key cant be empty')
        end

        # find application using server_key and app_id
        application = Application.find_by(server_key: server_key, app_id: app_id)
        if application.nil?
          render json: {
            error: {
              message: "Invalid app id or server key"
            }
          }, status: 404 and return
        end

        user_params = params[:user]
        if user_params.nil?
          raise InputError.new('param is missing or the value is empty: user')
        end

        user_id = user_params[:id]
        if user_id.nil? || user_id == ""
          raise InputError.new('User id is empty.')
        end

        user = User.find_by(id: user_id, application_id: application.id)
        if user.nil?
          render json: {
            error: {
              message: "User not found"
            }
          }, status: 404 and return
        end

        phone_number = user_params[:phone_number]
        if phone_number.present? && !phone_number.nil? && phone_number != ""
          phone_number = phone_number.strip().delete(' ')

          if User.where.not(id: user.id).where(application_id: user.application_id).exists?(phone_number: phone_number)
            raise InputError.new("Your submitted phone number already used by another user. Please use another phone number.")
          end

          user.phone_number = phone_number
        end

        fullname = user_params[:fullname]
        if fullname.present? && !fullname.nil? && fullname != ""
          fullname = fullname.strip().gsub(/\s+/, " ") # remove multi space to single space
          if fullname.length < 4
            raise InputError.new("Fullname minimum character is 4.")
          end

          user.fullname = fullname

          # Change username in SDK
          qiscus_sdk = QiscusSdk.new(application.app_id, application.qiscus_sdk_secret)
          qiscus_sdk.update_profile(user.qiscus_email, fullname)
        end

        email = user_params[:email]
        if email.present? && !email.nil? && email != ""
          if User.where.not(id: user.id).where(application_id: user.application_id).exists?(email: email)
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

        avatar_url = user_params[:avatar_url]
        if avatar_url.present? && !avatar_url.nil? && avatar_url != ""
          user.avatar_url = avatar_url

          # Change username in SDK
          qiscus_sdk = QiscusSdk.new(application.app_id, application.qiscus_sdk_secret)
          qiscus_sdk.update_profile(user.qiscus_email, nil, avatar_url)
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
end