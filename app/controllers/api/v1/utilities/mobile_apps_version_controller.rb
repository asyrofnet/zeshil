class Api::V1::Utilities::MobileAppsVersionController < ApplicationController

  # =begin
  # @apiVersion 1.0.0
  # @api {get} /api/v1/utilities/mobile_apps_version Check Mobile Apps Version
  # @apiDescription Check latest mobile apps version in database (for force update)
  # @apiName CheckMobileAppsVersion
  # @apiGroup Utilities
  #
  # @apiParam {String} app_id Application id, 'qisme', 'kiwari-stag', etc
  # @apiParam {String} platform Application platform: 'android', 'ios'
  # @apiParam {String} version Application version number (can be in version format like '1.1.1')
  # =end
  def index
    begin
      apps = Application.find_by(app_id: params[:app_id])

      if apps.nil?
        raise InputError.new("Application with given id is not found.")
      end

      if params[:platform].nil? || !params[:platform].present? || params[:platform] == ""
        raise InputError.new("Please specify your platform name.")
      end

      if params[:version].nil? || !params[:version].present? || params[:version] == ""
        raise InputError.new("Please specify your current application version.")
      end

      in_db_version = MobileAppsVersion.find_by(application_id: apps.id, platform: params[:platform])

      must_upgrade = false
      if in_db_version != nil  && params[:version] != nil
        updated_version = Versionomy.parse(in_db_version.version)
        client_version  = Versionomy.parse(params[:version])

        if updated_version > client_version
          must_upgrade = true
        end
      end

      render json: {
        data: {
          must_upgrade: must_upgrade
        }
      }
    rescue => e
      render json: {
        error: {
          message: e.message,
          class: e.class.name
        }
      }, status: 422 and return
    end
  end

end