require 'jwt'
require 'securerandom'

class Api::V1::Rest::AuthEmailNonceController < ApplicationController

  # =begin
  # @apiVersion 1.0.0
  # @api {post} /api/v1/rest/auth_email_nonce Login or Register using Server Key with nonce
  # @apiDescription Register user if not exist, otherwise only return access key
  # @apiName LoginOrRegisterEmailNonce
  # @apiGroup Rest API
  #
  # @apiParam {String} user[app_id] Application id, 'qisme', 'kiwari-stag', etc
  # @apiParam {String} user[secret_key] Application server key
  # @apiParam {String} user[email] Valid email to be register or sign in
  # @apiParam {String} user[fullname] Valid fullname to be register or sign in
  # @apiParam {String} [user[avatar_url]] Valid avatar_url to be register or sign in.
  # Default avatar_url = https://d1edrlpyc25xu0.cloudfront.net/image/upload/t5XWp2PBRt/1510641299-default_user_avatar.png
  # @apiParam {String} user[nonce] Nonce from SDK
  # =end
  def create
    begin
      user = nil
      identity_token = nil
      jwt = ""

      # delete all session if not used within one month
      # put here since it will be called everytime user want to login, no need in transaction because it must be deleted whether the transaction success or not
      AuthSession.where("auth_sessions.updated_at < ?", 1.month.ago).destroy_all

      ActiveRecord::Base.transaction do
        # app_id
        app_id = params[:user][:app_id]
        if app_id.nil? || app_id == ""
          raise Exception.new("App_id can't be empty.")
        end

        # server_key
        server_key = params[:user][:server_key]
        if server_key.nil? || server_key == ""
          raise Exception.new("Server key can't be empty.")
        end

        # find application using app_id and server_key
        application = Application.find_by(app_id: app_id, server_key: server_key)

        if application.nil?
          render json: {
            error: {
              message: "Application id not found or invalid server key."
            }
          }, status: 404 and return
        end

        # email
        email = params[:user][:email]
        if email.present? && !email.nil? && email != ""
          email = email.strip().delete(' ')

          if email == ""
            raise Exception.new("Email can't be empty.")
          end
        else
          raise Exception.new("Email can't be empty.")
        end

        # fullname
        fullname = params[:user][:fullname]
        if fullname.nil? || fullname == ""
          raise Exception.new("Fullname can't be empty.")
        end

        # avatar_url is optional
        avatar_url = params[:user][:avatar_url]

        # need to set default user avatar_url
        if avatar_url.nil?
          avatar_url = "https://d1edrlpyc25xu0.cloudfront.net/image/upload/t5XWp2PBRt/1510641299-default_user_avatar.png"
        end

        # nonce
        nonce = params[:user][:nonce]
        if nonce.nil? || nonce == ""
          raise Exception.new("Nonce can't be empty.")
        end

        user = User.find_by(email: email, application_id: application.id)

        # if nil then register
        if user.nil?
          role = Role.member
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
          new_user_credential["avatar_url"] = avatar_url

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
          user.avatar_url = new_user_credential["avatar_url"]
          user.save!

          # add user id to email to ensure that email is really unique
          email_sdk = "userid_" + user.id.to_s + "_" + user.qiscus_email

          # this ensure qiscus email sdk to be unique
          user.update_attribute(:qiscus_email, email_sdk)

          user_role = UserRole.new(user_id: user.id, role_id: role.id)
          user_role.save!
        else
          # if user is exist then do nothing
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

        # login or register to SDK using rest api
        email_sdk = user.qiscus_email
        username = user.fullname
        avatar_url = user.avatar_url
        password = SecureRandom.hex # generate random password for security reason

        qiscus_sdk = QiscusSdk.new(application.app_id, application.qiscus_sdk_secret)
        qiscus_token = qiscus_sdk.login_or_register_rest(email_sdk, password, username, avatar_url)
        user.update_columns(qiscus_token: qiscus_token) # always update qiscus token

        # generate identity_token using nonce
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

        identity_token = JWT.encode(payload, application.qiscus_sdk_secret, 'HS256', header)

      end

			jwt = ApplicationHelper.create_jwt_token(user, request)
      render json: {
        identity_token: identity_token,
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

    rescue Exception => e
      render json: {
        error: {
          message: e.message
        }
      }, status: 422 and return
    end
  end

end