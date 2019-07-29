class Dashboard::SuperAdmin::Application::CustomMenusController < SuperAdminController
  before_action :authorize_super_admin

  def index
    begin
      @application = ::Application.find(params[:application_id])
      @custom_menus = @application.custom_menus

      @path_segments = request.fullpath.split("/")

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
      if params[:caption] == "" || params[:url] == ""
        raise InputError.new("caption and url can't be empty.")
      end

      application = nil
      custom_menu = nil
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

        custom_menu = CustomMenu.new
        custom_menu.caption = params[:caption]
        custom_menu.url = params[:url]
        custom_menu.application_id = application.id
        custom_menu.save!
      end

      flash[:success] = "Success create new menu."
      redirect_to "/dashboard/super_admin/application/#{application.id}/custom_menus" and return
    rescue => e
      flash[:notice] = e.message
      redirect_back fallback_location: '/dashboard/super_admin/home'
    end
  end

  # get /dashboard/super_admin/application/2/custom_menus/4/delete
  def delete
    begin
      @custom_menu = ::CustomMenu.find_by(id: params[:id], application_id: params[:application_id])

      if @custom_menu.nil?
        flash[:notice] = "Menu not found"
        redirect_to '/dashboard/super_admin/home' and return
      end

      @custom_menu.destroy

      flash[:success] = "Success delete menu."
      redirect_to "/dashboard/super_admin/application/#{params[:application_id]}/custom_menus"
    rescue => e
      flash[:notice] = e.message
      redirect_to '/dashboard/super_admin/home'
    end
  end

  def show
    begin
      @custom_menu = ::CustomMenu.find_by(id: params[:id], application_id: params[:application_id])

      if @custom_menu.nil?
        flash[:notice] = "Menu not found"
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
      custom_menu = nil
      ActiveRecord::Base.transaction do
        custom_menu = ::CustomMenu.find(params[:custom_menu_id])
        custom_menu.caption = params[:caption] if params[:caption].present?
        custom_menu.url = params[:url] if params[:url].present?
        custom_menu.save!
      end

      flash[:success] = "Success update Menu."
      redirect_to "/dashboard/super_admin/application/#{params[:application_id]}/custom_menus"
    rescue => e
      flash[:notice] = e.message
      redirect_back fallback_location: '/dashboard/super_admin/home'
    end
  end

end
