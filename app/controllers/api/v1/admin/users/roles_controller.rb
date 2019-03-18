# add or remove role for specific user
class Api::V1::Admin::Users::RolesController < ProtectedController
  before_action :authorize_admin

  # =begin
  # @apiVersion 1.0.0
  # @api {get} /api/v1/admin/users/:id/roles List of User Roles
  # @apiName AdminListofUserRoles
  # @apiGroup Admin - User Role Management
  # @apiDescription Show current user's roles
  # @apiPermission Admin
  #
  # @apiParam {String} access_token Admin access token
  # @apiParam {Number} id User id
  # =end
  def index
    user = User.where(application_id: @current_user.application_id).where.not(id: @current_user.id)
    user = user.where(id: params[:user_id])
    user = user.first

    if user.nil?
      render json: {
        error: {
          message: 'User not found.'
        }
      }, status: 404 and return
    else
      render json: {
        data: user.roles
      } and return
    end
  end

  # =begin
  # @apiVersion 1.0.0
  # @api {post} /api/v1/admin/users/:id/roles Add Role to This User
  # @apiName AdminAddRoletoThisUser
  # @apiGroup Admin - User Role Management
  # @apiDescription Add Role to This User
  # @apiPermission Admin
  #
  # @apiParam {String} access_token Admin access token
  # @apiParam {Number} id User id
  # @apiParam {Array} role_id[] Role id to be added
  # =end
  def create
    begin
      ActiveRecord::Base.transaction do
        user = User.where(application_id: @current_user.application_id).where.not(id: @current_user.id)
        user = user.where(id: params[:user_id])
        user = user.first

        if user.nil?
          render json: {
            error: {
              message: 'User not found.'
            }
          }, status: 404 and return
        end

        ## now for each role id, add to this user

        if params[:role_id].kind_of?(Array) && params[:role_id].present?
          role_ids = params[:role_id].to_a

          role_ids.each do |rid|
            user_role = UserRole.find_by(user_id: user.id, role_id: rid.to_i)
            if user_role.nil?
              user_role = UserRole.new(user_id: user.id, role_id: rid.to_i)
              user_role.save!
            end
          end
        end

        render json: {
          data: user.roles
        } and return
      end
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
  # @api {delete} /api/v1/admin/users/:id/roles Delete Role of This User
  # @apiName AdminDeleteRoleofThisUser
  # @apiGroup Admin - User Role Management
  # @apiDescription Delete Role of This User
  # @apiPermission Admin
  #
  # @apiParam {String} access_token Admin access token
  # @apiParam {Number} id User id
  # @apiParam {Array} role_id[] Role id to be deleted
  # =end
  def destroy_roles
    begin
      ActiveRecord::Base.transaction do
        user = User.where(application_id: @current_user.application_id).where.not(id: @current_user.id)
        user = user.where(id: params[:user_id])
        user = user.first

        if user.nil?
          render json: {
            error: {
              message: 'User not found.'
            }
          }, status: 404 and return
        end

        ## now for each role id, add to this user

        if params[:role_id].kind_of?(Array) && params[:role_id].present?
          role_ids = params[:role_id].to_a

          role_ids.each do |rid|
            user_role = UserRole.find_by(user_id: user.id, role_id: rid.to_i)
            if user_role.nil? == false
              user_role.destroy
            end
          end
        end

        render json: {
          data: user.roles
        } and return
      end
    rescue Exception => e
      render json: {
        error: {
          message: e.message
        }
      }, status: 422 and return
    end
  end

end