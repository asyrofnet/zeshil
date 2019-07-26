require 'jwt'

class Api::V1::Admin::AuthController < ApplicationController
  before_action :ensure_new_session_params, only: [:create]
  before_action :ensure_verify_params, only: [:verify]

  # =begin
  # @apiVersion 1.0.0
  # @api {post} /api/v1/admin/auth Admin Login
  # @apiDescription Try to looking for user with given phone number and role = admin
  # @apiName AdminLogin
  # @apiGroup Admin - Auth
  #
  # @apiParam {String} user[app_id] Application id, 'qisme', 'kiwari-stag', etc
  # @apiParam {String} user[phone_number] Phone number to be register or sign in
  # =end
  def create
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

        user = User.find_by(phone_number: phone_number, application_id: application.id)

        # if user with given phone number AND app_id is EXIST then return object user
        if !user.nil?
          if user.is_admin
            passcode = SmsVerification.generate_code(phone_number, application.id)
            user.update_attribute(:passcode, passcode)
            # then send the passcode sms
            SmsVerification.request(user, user.passcode)

            if user.phone_number.include?("+628681")
              # send to qiscus
              messages = "#{application.app_name} : Passcode for account #{user.phone_number} is #{user.passcode}"
              SendToQiscus.send_message(110362, messages)
              p messages
            end

            render json: {
              data: user
            } and return

          else
            render json: {
              error: {
                message: "Unauthorized. User is not admin."
              }
            }, status: 401 and return
          end
        else
          render json: {
            error: {
              message: "Can't find user."
            }
          }, status: 404 and return
        end

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
  # @api {post} /api/v1/admin/auth/resend Admin Login Resend Passcode
  # @apiDescription Resend passcode for admin login
  # @apiName AdminAuthResendPasscode
  # @apiGroup Admin - Auth
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

        user = User.find_by(phone_number: params[:user][:phone_number], application_id: application.id)

        if !user.nil?
          if user.is_admin
            passcode = SmsVerification.generate_code(phone_number, application.id)
            user.update_attribute(:passcode, passcode)
            # then send the passcode sms
            SmsVerification.request(user, passcode)

            if user.phone_number.include?("+628681")
              # send to qiscus
              messages = "#{application.app_name} : Passcode for account #{user.phone_number} is #{user.passcode}"
              SendToQiscus.send_message(110362, messages)
              p messages
            end

            render json: {
              data: user
            } and return
          else
            render json: {
              error: {
                message: "Unauthorized. User is not admin."
              }
            }, status: 401 and return
          end
        else
          render json: {
            error: {
              message: "Can't find user."
            }
          }, status: 404 and return
        end
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
  # @api {post} /api/v1/admin/auth/verify Verify Admin Login passcode from SMS
  # @apiDescription Return access token and user object if successful
  # @apiName AdminLoginAuthVerify
  # @apiGroup Admin - Auth
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

        user = User.find_by(phone_number: params[:user][:phone_number],
          passcode: params[:user][:passcode], application_id: application.id)

        # if user with given phone number AND passcode AND app_id is EXIST then return object user
        if !user.nil?
          if user.is_admin
            # update passcode to nil (so user can't verify again once the code is used)
            user.update_attribute(:passcode, "")
            # now generate access_token for this user
            # jwt = JWT.encode({user_id: user.id, timestamp: Time.now}, ENV['JWT_KEY'], 'HS256')
            jwt = ApplicationHelper.create_jwt_token(user, request)
            render json: {
              access_token: jwt,
              data: user
            } and return
          else
            render json: {
              error: {
                message: "Unauthorized. User is not admin."
              }
            }, status: 401 and return
          end
        else
          render json: {
            error: {
              message: "Can't find user or wrong passcode."
            }
          }, status: 404 and return
        end

      end
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
      params.require(:user).permit(:phone_number, :app_id)
    end

    def ensure_verify_params
      params.require(:user).permit(:phone_number, :app_id, :passcode)
    end

end