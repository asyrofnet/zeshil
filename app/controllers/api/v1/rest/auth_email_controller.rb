require 'jwt'

class Api::V1::Rest::AuthEmailController < ApplicationController

  # =begin
  # @apiVersion 1.0.0
  # @api {post} /api/v1/rest/auth_email Login or Register using Server Key
  # @apiDescription Register user if not exist, otherwise only send passcode via email
  # @apiName LoginOrRegisterEmail
  # @apiGroup Rest API
  #
  # @apiParam {String} server_key Valid server key
  # @apiParam {String} user[email] Valid email to be register or sign in
  # @apiParam {String} user[name] Valid name to be register or sign in
  # @apiParam {String} user[phone_number] Valid phone_number to be register or sign in
  # @apiParam {Boolean} user[is_official] Is_official = 'true' or 'false' Set true if you want to create an official account
  # @apiParam {String} user[avatar_url] Valid avatar_url to be register or sign in. It's optional
  # =end
  def create
    begin
      user = nil
      jwt = ""

      # delete all session if not used within one month
      # put here since it will be called everytime user want to login, no need in transaction because it must be deleted whether the transaction success or not
      AuthSession.where("auth_sessions.updated_at < ?", 1.month.ago).destroy_all

      ActiveRecord::Base.transaction do
        # find application using server_key
        application = Application.find_by(server_key: params[:server_key])

        if application.nil?
          render json: {
            error: {
              message: "Invalid Server Key."
            }
          }, status: 404 and return
        end

        # check if user already exist or not
        email = params[:user][:email]
        if email.present? && !email.nil? && email != ""
          email = email.strip().delete(' ')

          if email == ""
            raise StandardError.new('Email is empty.')
          end
        else
          raise StandardError.new('Email is empty.')
        end

        # fullname
        fullname = params[:user][:name]
        if fullname.nil? || fullname == ""
          raise StandardError.new('Name is empty.')
        end

        # phone number
        phone_number = params[:user][:phone_number]
        # if phone_number.nil? || phone_number == ""
        #   raise StandardError.new('Phone number is empty.')
        # end
        phone_number = phone_number.strip().delete(' ')

        # is_official
        is_official = params[:user][:is_official]
        if is_official.nil? || is_official == ""
          raise StandardError.new('Is_official is empty.')
        end

        # avatar_url is optional
        avatar_url = params[:user][:avatar_url]

        user = User.find_by(email: email, application_id: application.id)

        # if nil then register
        if user.nil?
          # new user only for member level
          # but if is_official == true, its mean create new user with official account role
          if is_official == "false"
            role = Role.member
          else
            role = Role.official
          end
          if role.nil?
            render json: {
              error: {
                message: "Can't find user role, please contact admin to seed their database."
              }
            }, status: 404 and return
          end

          new_user_credential = params[:user].permit!

          email_sdk = email.tr('+', '').delete(' ')
          email_sdk = email_sdk.gsub('@', '.')
          email_sdk = email_sdk.downcase.gsub(/[^a-z0-9_.]/i, "") # only get alphanumeric and _ and . string only
          email_sdk = email_sdk + "@" + application.app_id + ".com" # will build string like user_email_name.email.com@app_id.com

          new_user_credential.delete(:app_id) # delete app id, replace with application_id
          new_user_credential["application_id"] = application.id
          new_user_credential["passcode"] = nil
          new_user_credential["qiscus_token"] = "qiscus_token" #
          new_user_credential["qiscus_email"] = email_sdk
          new_user_credential["email"] = email
          new_user_credential["fullname"] = fullname
          new_user_credential["secondary_phone_number"] = phone_number
          new_user_credential["country_code"] = phone_number.slice(0..2) # assuming the first 3 digits is country code

          # using class initiation to avoid user send another params (i.e fullname and it is saved)
          user = User.new
          user.email = new_user_credential["email"]
          # user.fullname = new_user_credential["email"] # fullname set to be nil to inform client
          user.application_id = new_user_credential["application_id"]
          user.passcode = new_user_credential["passcode"]
          user.qiscus_token = new_user_credential["qiscus_token"]
          user.qiscus_email = new_user_credential["qiscus_email"]
          user.fullname = new_user_credential["fullname"]
          user.secondary_phone_number = new_user_credential["secondary_phone_number"]
          user.is_public = false
          user.country_code = new_user_credential["country_code"]
          user.save!

          # Backend no need to register user in SDK
          # add user id to email to ensure that email is really unique
          email_sdk = "userid_" + user.id.to_s + "_" + user.qiscus_email
          qiscus_sdk = QiscusSdk.new(application.app_id, application.qiscus_sdk_secret)
          qiscus_token = qiscus_sdk.login_or_register(email_sdk, "password", fullname, avatar_url) # get qiscus token

          # this ensure qiscus email sdk to be unique
          user.update_attribute(:qiscus_email, email_sdk)
          user.update_attribute(:qiscus_token, qiscus_token)
          # set avatar_url if not nil
          user.update_attribute(:avatar_url, avatar_url) unless avatar_url.nil?

          user_role = UserRole.new(user_id: user.id, role_id: role.id)
          user_role.save!
        else
          # if exist then just update passcode
          # user.update_attribute(:passcode, SmsVerification.generate_code)
        end

        # here the user must already created, so we can add default contact (official user) here
        role_official_user = Role.official
        if role_official_user.nil? == false
          user_role_ids = UserRole.where(role_id: role_official_user.id).pluck(:user_id).to_a
          official_account = User.where("id IN (?)", user_role_ids).where(application_id: application.id)

          official_account.each do |oa|
            contact = Contact.find_by(user_id: user.id, contact_id: oa.id)

            if contact.nil?
              contact = Contact.new
              contact.user_id = user.id
              contact.contact_id = oa.id
              contact.save
            end
          end
        end

      end

			jwt = ApplicationHelper.create_jwt_token(user, request)
      render json: {
        access_token: jwt,
        data: user
      } and return

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