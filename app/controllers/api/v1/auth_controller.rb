require 'jwt'

class Api::V1::AuthController < ApplicationController
  before_action :ensure_new_session_params, only: [:create, :resend_passcode]
  before_action :ensure_verify_params, only: [:verify]

  # =begin
  # @apiVersion 1.0.0
  # @api {post} /api/v1/auth Login or Register
  # @apiDescription Register user if not exist, otherwise only send passcode via SMS
  # @apiName LoginOrRegister
  # @apiGroup Auth
  #
  # @apiParam {String} user[app_id] Application id, 'qisme', 'kiwari-stag', etc
  # @apiParam {String} user[phone_number] Phone number to be register or sign in
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
        phone_number = params[:user][:phone_number]
        if phone_number.nil? != false || phone_number != ""
          phone_number = phone_number.strip().delete(' ')
          # phone_number = PhonyRails.normalize_number(phone_number, default_country_code: 'ID')

          if phone_number == ""
            raise StandardError.new('Phone number is empty.')
          end
        else
          raise StandardError.new('Phone number is empty.')
        end
        user = User.find_by(phone_number: phone_number, application_id: application.id)

        # if nil then register
        if user.nil?
          passcode = SmsVerification.generate_code(phone_number, application.id)
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

          email_sdk = params[:user][:phone_number].tr('+', '').delete(' ')
          email_sdk = email_sdk.downcase.gsub(/[^a-z0-9_.]/i, "") # only get alphanumeric and _ and . string only
          email_sdk = email_sdk + "@" + application.app_id + ".com" # will build string like 085868xxxxxx@app_id.com

          new_user_credential.delete(:app_id) # delete app id, replace with application_id
          new_user_credential["application_id"] = application.id
          new_user_credential["passcode"] = passcode
          new_user_credential["qiscus_token"] = "qiscus_token"
          new_user_credential["qiscus_email"] = email_sdk
          new_user_credential["phone_number"] = phone_number
          new_user_credential["country_code"] = phone_number.slice(0..2) # assuming the first 3 digits is country code

          # using class initiation to avoid user send another params (i.e fullname and it is saved)
          user = User.new
          user.phone_number = new_user_credential["phone_number"]
          # user.fullname = new_user_credential["phone_number"] # fullname set to be nil to inform client
          user.application_id = new_user_credential["application_id"]
          user.passcode = new_user_credential["passcode"]
          user.qiscus_token = new_user_credential["qiscus_token"]
          user.qiscus_email = new_user_credential["qiscus_email"]
          user.is_public = false
          user.country_code = new_user_credential["country_code"]
          user.save!

          # Backend no need to register user in SDK (but if it's okay even it is happen (for easy debugging when trying qisus chat room))
          # add user id to email to ensure that email is really unique
          email_sdk = "userid_" + user.id.to_s + "_" + user.qiscus_email

          # this ensure qiscus email sdk to be unique
          user.update_attribute(:qiscus_email, email_sdk)

          user_role = UserRole.new(user_id: user.id, role_id: role.id)
          user_role.save!

          # username is user phone_number
          username = new_user_credential["phone_number"]
        else
          # if exist then just update passcode
          # for now, update passcode only when passcode field in database is nil
          # if passcode field not nil its mean user request to resend passcode. Then take the existing passcode value
          # handling race condition with locking
          user.with_lock do
            if user.passcode.nil? || user.passcode == ""
              passcode = SmsVerification.generate_code(phone_number, application.id)
              user.update_columns(passcode: passcode)
            else
              # get current passcode
              passcode = user.passcode
            end
            email_sdk = user.qiscus_email
            username = user.fullname
          end
        end


        # Calling SDK login or register placed in here to handle token changes. For now token can be changed via rest api
        qiscus_sdk = QiscusSdk.new(application.app_id, application.qiscus_sdk_secret)
        qiscus_token = qiscus_sdk.login_or_register(email_sdk, "password", username) # get qiscus token
        user.update_columns(qiscus_token: qiscus_token)

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

        # then send the passcode sms
        SmsVerification.request(user, passcode)

        # For debugging or quality assurance testing, send passcode to Qiscus if phone number contains "+628681"
        # why "+628681" because it is a valid predecessor phone number in Indonesia,
        # since model using phony_plausible validation it need to be use valid number to register
        if user.phone_number.include?("+628681")
          # send to qiscus
          messages = "#{application.app_name} : Passcode for account #{user.phone_number} is #{user.passcode}"
          SendToQiscus.send_message(110362, messages)
        end
      end

      render json: {
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


  # =begin
  # @apiVersion 1.0.0
  # @api {post} /api/v1/auth/resend_passcode Resend passcode
  # @apiDescription Resend passcode
  # @apiName ResendPasscode
  # @apiGroup Auth
  #
  # @apiParam {String} user[app_id] User application id
  # @apiParam {String} user[phone_number] Registered phone number
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

        phone_number = params[:user][:phone_number]
        # phone_number = PhonyRails.normalize_number(phone_number, default_country_code: 'ID')
        user = User.find_by(phone_number: phone_number, application_id: application.id)

        if !user.nil?
          # for now, no change passcode on resend passcode
          passcode = user.passcode
          # passcode = SmsVerification.generate_code
          # user.update_attribute(:passcode, passcode)
          # then send the passcode sms
          SmsVerification.request(user, passcode)

          render json: {
            data: user
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
          message: e.message
        }
      }, status: 422 and return
    end
  end

  # =begin
  # @apiVersion 1.0.0
  # @api {post} /api/v1/auth/verify Verify passcode from SMS
  # @apiDescription Return access token and user object if successful
  # @apiName AuthVerify
  # @apiGroup Auth
  #
  # @apiParam {String} user[app_id] Application id, 'qisme', 'kiwari-stag', etc
  # @apiParam {String} user[phone_number] Phone number to validate
  # @apiParam {String} user[passcode] Passcode from SMS
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

        phone_number = params[:user][:phone_number]
        # phone_number = PhonyRails.normalize_number(phone_number, default_country_code: 'ID')

        user = User.find_by(phone_number: phone_number,
          passcode: params[:user][:passcode], application_id: application.id)

        # if user with given phone number AND passcode AND app_id is EXIST then return object user
        if !user.nil?
          # update passcode to nil (so user can't verify again once the code is used)
          user.update_columns(passcode: nil) # using update_columns to prevent calling callback
          # now generate access_token for this user
          jwt = ApplicationHelper.create_jwt_token(user, request)
          render json: {
            access_token: jwt,
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
          backtrace: e.backtrace
        }
      }, status: 422 and return
    end
  end

  private
    def ensure_new_session_params
      params.require(:user).permit(:phone_number, :app_id)
    end

    def ensure_verify_params
      params.require(:user).permit(:phone_number, :app_id, :passcode)
    end

end
