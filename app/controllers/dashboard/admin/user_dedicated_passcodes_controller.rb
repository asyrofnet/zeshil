class Dashboard::Admin::UserDedicatedPasscodesController < AdminController
  before_action :authorize_admin

  def index
    begin
      @application = ::Application.find(@current_admin.application.id)
      @passcodes = ::UserDedicatedPasscode.where(application_id: @application.id)

      @path_segments = request.fullpath.split("/")

      render "index"
    rescue Exception => e
      flash[:notice] = e.message
      redirect_to '/dashboard/admin/home'
    end
  end

  def new
    @application = ::Application.find(@current_admin.application.id)
    render "new"
  end

  def create
    begin
      if params[:user_phone_number] == "" || params[:passcode] == ""
        raise Exception.new("application_id, phone_number, or passcode can't be empty.")
      end

      application = nil
      passcode = nil
      ActiveRecord::Base.transaction do
        # check the application id
        application = ::Application.find_by(id: @current_admin.application.id)

        if application.nil?
          render json: {
            error: {
              message: "Application id is not found."
            }
          }, status: 404 and return
        end

        # check user id
        user = ::User.find_by(phone_number: params[:user_phone_number], application_id: application.id)

        if user.nil?
          raise Exception.new("User not found")

          render json: {
            error: {
              message: "User not found."
            }
          }, status: 404 and return
        end

        passcode = UserDedicatedPasscode.new
        passcode.application_id = application.id
        passcode.user_id = user.id
        passcode.passcode = params[:passcode]
        passcode.save!
      end

      flash[:success] = "Success create new dedicated passcode."
      redirect_to "/dashboard/admin/user_dedicated_passcodes" and return
    rescue Exception => e
      flash[:notice] = e.message
      redirect_back fallback_location: '/dashboard/admin/home'
    end
  end

  def delete
    begin
      @passcode = ::UserDedicatedPasscode.find_by(id: params[:id], application_id: @current_admin.application.id)

      if @passcode.nil?
        flash[:notice] = "Passcode not found"
        redirect_to '/dashboard/admin/home' and return
      end

      @passcode.destroy

      flash[:success] = "Success delete passcode."
      redirect_to "/dashboard/admin/user_dedicated_passcodes"
    rescue Exception => e
      flash[:notice] = e.message
      redirect_to '/dashboard/admin/home'
    end
  end

  def show
    begin
      @passcode = ::UserDedicatedPasscode.find_by(id: params[:id], application_id: @current_admin.application.id)

      if @passcode.nil?
        flash[:notice] = "Passcode not found"
        redirect_to '/dashboard/admin/home' and return
      end

      render "show"
    rescue Exception => e
      flash[:notice] = e.message
      redirect_to '/dashboard/admin/home'
    end
  end

  def update
    begin
      application = nil
      passcode = nil
      ActiveRecord::Base.transaction do
        application = ::Application.find_by(id: @current_admin.application.id)

        # check user
        user = ::User.find_by(phone_number: params[:user_phone_number], application_id: application.id)
        if user.nil?
          raise Exception.new("user not found. please input registered user")
        end

        passcode = ::UserDedicatedPasscode.find(params[:passcode_id])
        passcode.application_id = application.id if application.id.present?
        passcode.user_id = user.id if user.id.present?
        passcode.passcode = params[:passcode] if params[:passcode].present?
        passcode.save!
      end

      flash[:success] = "Success update passcode."
      redirect_to "/dashboard/admin/user_dedicated_passcodes"
    rescue Exception => e
      flash[:notice] = e.message
      redirect_back fallback_location: '/dashboard/super_admin/home'
    end
  end

end