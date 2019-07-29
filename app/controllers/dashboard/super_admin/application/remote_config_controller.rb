class Dashboard::SuperAdmin::Application::RemoteConfigController < SuperAdminController
  before_action :authorize_super_admin

  def index
    begin
      @application = ::Application.find(params[:application_id])
      @features = @application.features

      render "index"
    rescue => e
      flash[:notice] = e.message
      redirect_to '/dashboard/super_admin/home'
    end
  end

  def new
    @application = ::Application.find(params[:application_id])
    render "new"
  end

  def create
    begin
      if params[:feature_id] == "" || params[:feature_name] == ""
        raise InputError.new("feature_id and feature_name can't be empty.")
      end

      application = nil
      feature = nil
      ActiveRecord::Base.transaction do
        # check the application id
        application = ::Application.find_by(id: params[:application_id])

        if application.nil?
          render json: {
            error: {
              message: "Application id is not found."
            }
          }, status: 404 and return
        end

        feature = Feature.new
        feature.feature_id = params[:feature_id]
        feature.feature_name = params[:feature_name]
        feature.description = params[:description]
        feature.application_id = application.id
        feature.save!
      end

      flash[:success] = "Success create new feature."
      redirect_to "/dashboard/super_admin/application/#{application.id}/features" and return
    rescue => e
      flash[:notice] = e.message
      redirect_back fallback_location: '/dashboard/super_admin/home'
    end
  end

  # get /dashboard/super_admin/application/2/features/4/delete
  def delete
    begin
      @feature = ::Feature.find_by(id: params[:id], application_id: params[:application_id])

      if @feature.nil?
        flash[:notice] = "Feature not found"
        redirect_to '/dashboard/super_admin/home' and return
      end

      @feature.destroy

      flash[:success] = "Success delete feature."
      redirect_to "/dashboard/super_admin/application/#{params[:application_id]}/features"
    rescue => e
      flash[:notice] = e.message
      redirect_to '/dashboard/super_admin/home'
    end
  end

  def show
    begin
      @feature = ::Feature.find_by(id: params[:id], application_id: params[:application_id])

      if @feature.nil?
        flash[:notice] = "Feature not found"
        redirect_to '/dashboard/super_admin/home' and return
      end

      render "show"
    rescue => e
      flash[:notice] = e.message
      redirect_to '/dashboard/super_admin/home'
    end
  end

  def update
    begin
      feature = nil
      ActiveRecord::Base.transaction do
        feature = ::Feature.find(params[:feature_id])
        feature.feature_id = params[:input_feature_id] if params[:input_feature_id].present?
        feature.feature_name = params[:feature_name] if params[:feature_name].present?
        feature.description = params[:description]
        feature.save!
      end

      flash[:success] = "Success update feature."
      redirect_to "/dashboard/super_admin/application/#{params[:application_id]}/features"
    rescue => e
      flash[:notice] = e.message
      redirect_back fallback_location: '/dashboard/super_admin/home'
    end
  end

end