class Api::V1::Admin::Utilities::MobileAppsVersionController < ProtectedController
  before_action :authorize_admin

  # =begin
  # @apiVersion 1.0.0
  # @api {get} /api/v1/admin/utilities/mobile_apps_version List Mobile Apps Version
  # @apiDescription List of registered mobile version
  # @apiName MobileAppsVersionList
  # @apiGroup Utilities Mobile Application
  # @apiPermission Admin
  #
  # @apiParam {String} access_token Admin access token
  # =end
  def index
    begin
      app_version = MobileAppsVersion.where(application_id: @current_user.application.id)

      render json: {
        data: app_version
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
  # @api {post} /api/v1/admin/utilities/mobile_apps_version Create Mobile Apps Version
  # @apiDescription Update or create mobile version to force update
  # @apiName MobileAppsVersionCreate
  # @apiGroup Utilities Mobile Application
  # @apiPermission Admin
  #
  # @apiParam {String} access_token Admin access token
  # @apiParam {String} platform Mobile platform
  # @apiParam {String} version Mobile version
  # =end
  def create
    begin
      apps = @current_user.application

      if params[:platform].nil? || !params[:platform].present? || params[:platform] == ""
        raise StandardError.new("Please specify your platform name.")
      else
        if params[:platform].downcase.delete(' ') != "android" && params[:platform].downcase.delete(' ') != "ios"
          raise StandardError.new("Permitted platform is 'android' or 'ios'.")
        end
      end

      if params[:version].nil? || !params[:version].present? || params[:version] == ""
        raise StandardError.new("Please specify your application version.")
      end
        
      app_version = MobileAppsVersion.find_by(application_id: apps.id, platform: params[:platform])

      # if nil, create a new one
      if app_version.nil?
        app_version = MobileAppsVersion.new
        app_version.application_id = apps.id
        app_version.platform = params[:platform].delete(' ').downcase
        app_version.version = Versionomy.parse(params[:version].delete(' ').downcase)

        app_version.save!
      else
        # if not nil, just update current one
        app_version.update_attribute(:version, Versionomy.parse(params[:version].delete(' ').downcase))
      end

      render json: {
        data: app_version
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
