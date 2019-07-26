require 'jwt'
require 'securerandom'

class Api::V1::AuthEmailNonceController < ApplicationController
	before_action :ensure_new_session_params, only: [:create, :resend_passcode]
	before_action :ensure_verify_params, only: [:verify]

  # =begin
  # @apiVersion 1.0.0
  # @api {post} /api/v1/auth_email_nonce Login or Register
  # @apiDescription Register user if not exist, otherwise only send passcode via email
  # @apiName LoginOrRegisterEmail
  # @apiGroup Auth Email Nonce
  #
  # @apiParam {String} user[app_id] Application id, 'qisme', 'kiwari-stag', etc
  # @apiParam {String} user[email] Valid email to be register or sign in
  # =end
  def create
    begin
      user = nil
      jwt = ""

      # delete all session if not used within one month
      # put here since it will be called everytime user want to login, no need in transaction because it must be deleted whether the transaction success or not
      AuthSession.where("auth_sessions.updated_at < ?", 1.month.ago).destroy_all

      ActiveRecord::Base.transaction do
        # check the application id
        application = Application.find_by(app_id: params[:user][:app_id])

        if application.nil?
          render json: {
            error: {
              message: "Application id is not found."
            }
          }, status: 404 and return
        end

        # check if user already exist or not
        email = params[:user][:email]
        if email.present? && !email.nil? && email != ""
          email = email.strip().delete(' ')

          if email == ""
            raise InputError.new('Email is empty.')
          end
        else
          raise InputError.new('Email is empty.')
        end
        user = User.find_by(email: email, application_id: application.id)

        # if nil then register
        if user.nil?
          passcode = SmsVerification.generate_code(email, application.id)
          # new user only for member level
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
          new_user_credential["passcode"] = passcode
          new_user_credential["qiscus_token"] = "qiscus_token" #
          new_user_credential["qiscus_email"] = email_sdk
          new_user_credential["email"] = email
          # set default user avatar
          new_user_credential["avatar_url"] = "https://d1edrlpyc25xu0.cloudfront.net/image/upload/t5XWp2PBRt/1510641299-default_user_avatar.png"

          # using class initiation to avoid user send another params (i.e fullname and it is saved)
          user = User.new
          user.email = new_user_credential["email"]
          # user.fullname = new_user_credential["email"] # fullname set to be nil to inform client
          user.application_id = new_user_credential["application_id"]
          user.passcode = new_user_credential["passcode"]
          user.qiscus_token = new_user_credential["qiscus_token"]
          user.qiscus_email = new_user_credential["qiscus_email"]
          user.avatar_url = new_user_credential["avatar_url"]
          user.is_public = false
          user.save!

          # Backend no need to register user in SDK
          # add user id to email to ensure that email is really unique
          email_sdk = "userid_" + user.id.to_s + "_" + user.qiscus_email

          # this ensure qiscus email sdk to be unique
          user.update_attribute(:qiscus_email, email_sdk)

          user_role = UserRole.new(user_id: user.id, role_id: role.id)
          user_role.save!

          # username is user email
          username = new_user_credential["email"]
        else
          # if exist then just update passcode
          # for now, update passcode only when passcode field in database is nil
          # if passcode field not nil its mean user request to resend passcode. Then take the existing passcode value
          # handling race condition with locking
          user.with_lock do
            if user.passcode.nil? || user.passcode == ""
              passcode = SmsVerification.generate_code(user.phone_number, application.id)
              user.update_columns(passcode: passcode)
            else
              # get current passcode
              passcode = user.passcode
            end
            email_sdk = user.qiscus_email
            username = user.fullname
          end
        end

        password = SecureRandom.hex # generate random password for security reason

        avatar_url = user.avatar_url
        # set default username
        if username.nil?
          username = user.email
        end

        # set default user avatar
        if avatar_url.nil?
          avatar_url = "https://d1edrlpyc25xu0.cloudfront.net/image/upload/t5XWp2PBRt/1510641299-default_user_avatar.png"
          user.update_attribute(:avatar_url, avatar_url)
        end

        # login or register to SDK using rest api
        qiscus_sdk = QiscusSdk.new(application.app_id, application.qiscus_sdk_secret)
        qiscus_token = qiscus_sdk.login_or_register_rest(email_sdk, password, username, avatar_url)
        user.update_columns(qiscus_token: qiscus_token) # always update qiscus token

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

        # then send the passcode to email
        PasscodeMailer.send_passcode(user).deliver_later(wait: 1.second)

        # For debugging or quality assurance testing, send passcode to Qiscus if email contains "@mailinator.com"
        # why "@mailinator.com because we need to differentiate whether it is testing account or not
        if user.email.include?("@mailinator")
          # send to qiscus
          messages = "#{application.app_name} : Passcode for account #{user.email} is #{user.passcode}"
          SendToQiscus.send_message(110362, messages)
        end

      end

      render json: {
        data: {
          message: "Passcode sent. Please verify your account."
        }
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
          message: e.message,
          class: e.class.name
        }
      }, status: 422 and return
    end
  end

  # =begin
  # @apiVersion 1.0.0
  # @api {post} /api/v1/auth_email_nonce/resend_passcode Resend passcode
  # @apiDescription Resend passcode
  # @apiName ResendPasscodeEmail
  # @apiGroup Auth Email Nonce
  #
  # @apiParam {String} user[app_id] User application id
  # @apiParam {String} user[email] Registered email
  # =end
  def resend_passcode
    begin
      ActiveRecord::Base.transaction do
        # check the application id
        application = Application.find_by(app_id: params[:user][:app_id])

        if application.nil?
          render json: {
            error: {
              message: "Application id is not found."
            }
          }, status: 404 and return
        end

        email = params[:user][:email]
        if email.present? && !email.nil? && email != ""
          email = email.strip().delete(' ')

          if email == ""
            raise InputError.new('Email is empty.')
          end
        else
          raise InputError.new('Email is empty.')
        end

        user = User.find_by(email: email, application_id: application.id)

        if !user.nil?
          # for now, no change passcode on resend passcode
          if !user.passcode.nil?
            passcode = user.passcode
          else
            passcode = SmsVerification.generate_code(email, application.id)
            user.update_attribute(:passcode, passcode)
          end
          PasscodeMailer.send_passcode(user).deliver_later(wait: 1.second)

          render json: {
            data: {
              message: "Passcode sent. Please verify your account."
            }
          } and return
        else
          render json: {
            error: {
              message: "Can't find user."
            }
          }, status: 404 and return
        end
      end

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
          message: e.message,
          class: e.class.name
        }
      }, status: 422 and return
    end
  end

  # =begin
  # @apiVersion 1.0.0
  # @api {post} /api/v1/auth_email_nonce/verify Verify passcode from Email
  # @apiDescription Return access token and user object if successful
  # @apiName AuthVerifyEmail
  # @apiGroup Auth Email Nonce
  #
  # @apiParam {String} user[app_id] Application id, 'qisme', 'kiwari-stag', etc
  # @apiParam {String} user[email] Email to validate
  # @apiParam {String} user[passcode] Passcode from email
  # @apiParam {String} user[nonce] Nonce from SDK
  # =end
  def verify
    begin
      ActiveRecord::Base.transaction do
        # check the application id
        application = Application.find_by(app_id: params[:user][:app_id])

        if application.nil?
          render json: {
            error: {
              message: "Application id is not found."
            }
          }, status: 404 and return
        end

        email = params[:user][:email]
        if email.present? && !email.nil? && email != ""
          email = email.strip().delete(' ')

          if email == ""
            raise InputError.new('Email is empty.')
          end
        else
          raise InputError.new('Email is empty.')
        end

        # check empty passcode
        passcode = params[:user][:passcode]
        if passcode.nil? || passcode.blank?
          raise InputError.new('passcode cannot be empty.')
        end

        # check empty nonce
        nonce = params[:user][:nonce]
        if nonce.nil? || nonce.blank?
          raise InputError.new('nonce cannot be empty.')
        end

        user = User.find_by(email: email,
          passcode: passcode, application_id: application.id)

        # if user with given phone number AND passcode AND app_id is EXIST then return object user
        if !user.nil?
          # update passcode to nil (so user can't verify again once the code is used)
          user.update_attribute(:passcode, nil)
          # now generate access_token for this user
          jwt = ApplicationHelper.create_jwt_token(user, request)

          # need to destroy access_token since it using auth nonce
          # release_date = "2017-11-23 15:30:00" # set auth nonce release date
          # AuthSession.where("updated_at < ? AND user_id = ?", release_date, user.id).destroy_all

          email_sdk = user.qiscus_email
          username = user.fullname
          if username.nil?
            username = params[:user][:email]
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
            access_token: jwt,
            identity_token: identity_token,
            data: user
          } and return
        else
          render json: {
            error: {
              message: "Can't find user or wrong passcode."
            }
          }, status: 404 and return
        end

      end

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
          message: e.message,
          class: e.class.name
        }
      }, status: 422 and return
    end
  end

  private
    def ensure_new_session_params
      params.require(:user).permit(:email, :app_id)
    end

    def ensure_verify_params
      params.require(:user).permit(:email, :app_id, :passcode)
    end

end
