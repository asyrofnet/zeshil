require 'jwt'
class Api::V1::Admin::AuthEmailController < ApplicationController
  before_action :ensure_new_session_params, only: [:create]
  before_action :ensure_verify_params, only: [:verify]

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

        email = params[:user][:email]

        if email.present? && !email.nil? && email != ""
          email = email.strip().delete(' ')

          if email == ""
            raise Exception.new('Email is empty.')
          end
        else
          raise Exception.new('Email is empty.')
        end

        user = User.find_by(email: email, application_id: application.id)

        # if user with given phone number AND app_id is EXIST then return object user
        if !user.nil?
          if user.is_admin

            # check dedicated passcode
            passcode = SmsVerification.generate_code(user.phone_number, application.id)
            user.update_attribute(:passcode, passcode)

            PasscodeMailer.send_passcode(user).deliver_later(wait: 1.second)

            # For debugging or quality assurance testing, send passcode to Qiscus if email contains "@mailinator.com"
            # why "@mailinator.com because we need to differentiate whether it is testing account or not
            if user.email.include?("@mailinator")
              # send to qiscus
              messages = "#{application.app_name} : Passcode for account #{user.email} is #{user.passcode}"
              SendToQiscus.send_message(110362, messages)
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
    rescue Exception => e
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
