class Dashboard::Admin::MobileVersionsController < AdminController
  before_action :authorize_admin

  # template dashboard/admin/mobile_versions/index
  def index
    begin
      @application = ::Application.find(@current_admin.application.id)
      @mobile_apps_version = MobileAppsVersion::where(application_id: @current_admin.application.id)
      render "index"
    rescue Exception => e
      flash[:notice] = e.message
      redirect_back fallback_location: '/dashboard/admin/home'
    end
  end

  def create_or_update
    begin
      @application = ::Application.find(@current_admin.application.id)

      if params[:platform].nil? || !params[:platform].present? || params[:platform] == ""
        raise Exception.new("Please specify your platform name.")
      else
        if params[:platform].downcase.delete(' ') != "android" && params[:platform].downcase.delete(' ') != "ios"
          raise Exception.new("Permitted platform is 'android' or 'ios'.")
        end
      end

      if params[:version].nil? || !params[:version].present? || params[:version] == ""
        raise Exception.new("Please specify your application version.")
      end
        
      app_version = MobileAppsVersion.find_by(application_id: @application.id, platform: params[:platform])

      # if nil, create a new one
      if app_version.nil?
        app_version = MobileAppsVersion.new
        app_version.application_id = @application .id
        app_version.platform = params[:platform].delete(' ').downcase
        app_version.version = Versionomy.parse(params[:version].delete(' ').downcase)

        app_version.save!
      else
        # if not nil, just update current one
        app_version.update_attribute(:version, Versionomy.parse(params[:version].delete(' ').downcase))
      end

      flash[:success] = "Success update #{app_version.platform.titleize} to #{app_version.version}."
      redirect_back fallback_location: '/dashboard/admin/home' and return

    rescue Exception => e
      flash[:notice] = e.message
      redirect_back fallback_location: '/dashboard/admin/home'
    end
  end

end