class Api::V1::UsersController < ProtectedController
  before_action :authorize_user

  # =begin
  # @apiVersion 1.0.0
  # @api {get} /api/v1/users/ Show Detail Multiple Users
  # @apiDescription Show detail user using multipe user_id
  # @apiName ShowDetailMultipleUser
  # @apiGroup User
  #
  # @apiParam {String} access_token User access token
  # @apiParam {Array} user_id[] Array of user_id
  # =end
  def index
    begin
      users = nil
      ActiveRecord::Base.transaction do
        application = @current_user.application
        user_ids = params[:user_id]
        if !user_ids.is_a?(Array)
          raise InputError.new("User id must be an array of user id.")
        end

        users = User.where(id: user_ids.to_a, application_id: application.id)

        users = users.map(&:as_contact_json)
        contact_id = @current_user.contacts.pluck(:contact_id)
        users = users.map do |e|
          is_contact = contact_id.include?(e["id"])
          e.merge!('is_contact' => is_contact )
        end
      end

      render json: {
        data: users
      }
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
  # @api {get} /api/v1/users/:id Show Detail Single User
  # @apiDescription Show detail user using single user_id
  # @apiName ShowDetailSingleUser
  # @apiGroup User
  #
  # @apiParam {String} access_token User access token
  # @apiParam {Number} id Where id is user_id
  # =end
  def show
    begin
      user = nil
      ActiveRecord::Base.transaction do
        application = @current_user.application
        user_id = params[:id]
        if user_id.nil?
          raise InputError.new("User id must be present.")
        end

        user = User.find_by(id: user_id, application_id: application.id)

        if user.nil?
          raise InputError.new("User not found")
        end

        contact = Contact.find_by(user_id: @current_user.id, contact_id: user.id)
        is_contact = false
        is_contact = true if !contact.nil?
        user = user.as_json
        user = user.merge('is_contact' => is_contact)
      end

      render json: {
        data: user
      }
    rescue => e
      render json: {
        error: {
          message: e.message
        }
      }, status: 422 and return
    end
  end

end