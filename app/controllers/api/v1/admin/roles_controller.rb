class Api::V1::Admin::RolesController < ProtectedController
  before_action :authorize_admin

  # =begin
  # @apiVersion 1.0.0
  # @api {get} /api/v1/admin/roles List of Roles
  # @apiName AdminListofRoles
  # @apiGroup Admin - Role Management
  # @apiPermission Admin
  #
  # @apiParam {String} access_token Admin access token
  # =end
  def index
    roles = Role.all
    render json: {
      data: roles
    }
  end

end