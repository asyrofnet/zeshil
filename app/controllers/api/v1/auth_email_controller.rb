require 'jwt'

class Api::V1::AuthEmailController < ApplicationController
	before_action :ensure_new_session_params, only: [:create, :resend_passcode]
	before_action :ensure_verify_params, only: [:verify]

  # =begin
  # @apiVersion 1.0.0
  # @api {post} /api/v1/auth_email Login or Register
  # @apiDescription Register user if not exist, otherwise only send passcode via email
  # @apiName LoginOrRegisterEmail
  # @apiGroup Auth Email
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
            raise StandardError.new('Email is empty.')
          end
        else
          raise StandardError.new('Email is empty.')
        end
        user = User.find_by(email: email, application_id: application.id)

        # if nil then register
        if user.nil?
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
          new_user_credential["passcode"] = SmsVerification.generate_code(email, application.id)
          new_user_credential["qiscus_token"] = "qiscus_token" #
          new_user_credential["qiscus_email"] = email_sdk
          new_user_credential["email"] = email

          # using class initiation to avoid user send another params (i.e fullname and it is saved)
          user = User.new
          user.email = new_user_credential["email"]
          # user.fullname = new_user_credential["email"] # fullname set to be nil to inform client
          user.application_id = new_user_credential["application_id"]
          user.passcode = new_user_credential["passcode"]
          user.qiscus_token = new_user_credential["qiscus_token"]
          user.qiscus_email = new_user_credential["qiscus_email"]
          user.is_public = false
          user.save!

          # Backend no need to register user in SDK
          # add user id to email to ensure that email is really unique
          email_sdk = "userid_" + user.id.to_s + "_" + user.qiscus_email
          qiscus_sdk = QiscusSdk.new(application.app_id, application.qiscus_sdk_secret)
          qiscus_token = qiscus_sdk.login_or_register(email_sdk, "password", email) # get qiscus token

          # this ensure qiscus email sdk to be unique
          user.update_attribute(:qiscus_email, email_sdk)
          user.update_attribute(:qiscus_token, qiscus_token)

          user_role = UserRole.new(user_id: user.id, role_id: role.id)
          user_role.save!
        else
          # if exist then just update passcode
          user.update_attribute(:passcode, SmsVerification.generate_code(user.phone_number, application.id))
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

        # then send the passcode to email
        # SmsVerification.request(user, user.passcode)
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
  # @api {post} /api/v1/auth_email/resend_passcode Resend passcode
  # @apiDescription Resend passcode
  # @apiName ResendPasscodeEmail
  # @apiGroup Auth Email
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
            raise StandardError.new('Email is empty.')
          end
        else
          raise StandardError.new('Email is empty.')
        end

        user = User.find_by(email: email, application_id: application.id)

        if !user.nil?
          passcode = SmsVerification.generate_code(phone_number, application.id)
          user.update_attribute(:passcode, passcode)
          # then send the passcode to email
          # SmsVerification.request(user, passcode)
          PasscodeMailer.send_passcode(user).deliver_later(wait: 1.second)

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
  # @api {post} /api/v1/auth_email/verify Verify passcode from Email
  # @apiDescription Return access token and user object if successful
  # @apiName AuthVerifyEmail
  # @apiGroup Auth Email
  #
  # @apiParam {String} user[app_id] Application id, 'qisme', 'kiwari-stag', etc
  # @apiParam {String} user[email] Email to validate
  # @apiParam {String} user[passcode] Passcode from email
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
            raise StandardError.new('Email is empty.')
          end
        else
          raise StandardError.new('Email is empty.')
        end

        user = User.find_by(email: email,
          passcode: params[:user][:passcode], application_id: application.id)

        # if user with given phone number AND passcode AND app_id is EXIST then return object user
        if !user.nil?
          # update passcode to nil (so user can't verify again once the code is used)
          user.update_attribute(:passcode, nil)
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
          message: e.message
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
