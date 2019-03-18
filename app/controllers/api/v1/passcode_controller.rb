require 'jwt'

class Api::V1::PasscodeController < ApplicationController
  before_action :ensure_new_session_params, only: [:create, :resend_passcode]
  before_action :ensure_verify_params, only: [:verify]

  # =begin
  # @apiVersion 1.0.0
  # @api {post} /api/v1/passcode Request passcode
  # @apiDescription Request passcode for existing user
  # @apiName RequestPasscode
  # @apiGroup Passcode
  #
  # @apiParam {String} user[app_id] Application id, 'qisme', 'kiwari-stag', etc
  # @apiParam {String} user[phone_number] Phone number to be register or sign in
  # =end

  # This api for finexis support
  def create
    begin
      user = nil

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

          if phone_number == ""
            raise Exception.new('Phone number is empty.')
          end
        else
          raise Exception.new('Phone number is empty.')
        end
        user = User.find_by(phone_number: phone_number, application_id: application.id)

        passcode = nil
        # only generate passcode for existing user
        if user.nil?
            raise Exception.new('Cant find user.')
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
          end
        end

        # then send the passcode sms
        SmsVerification.request(user, passcode)
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

    rescue Exception => e
      render json: {
        error: {
          message: e.message
        }
      }, status: 422 and return
    end
  end

  # =begin
  # @apiVersion 1.0.0
  # @api {post} /api/v1/passcode/verify Verify passcode from SMS
  # @apiDescription Return access token and user object if successful
  # @apiName PasscodeVerify
  # @apiGroup Passcode
  #
  # @apiParam {String} user[app_id] Application id, 'qisme', 'kiwari-stag', etc
  # @apiParam {String} user[phone_number] Phone number to validate
  # @apiParam {String} user[passcode] Passcode from SMS
  # =end

  # This api for finexis support
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

    rescue Exception => e
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
