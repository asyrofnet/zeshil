class Dashboard::User::HomeController < UserController
  before_action :authorize_user

  # template dashboard/user/home/index
  def index
    begin
      @user = User.find_by(id: @current_user.id)

      if @user.nil?
        flash[:notice] = "User not found"
        redirect_to '/dashboard/user/home' and return
      end

      @application = ::Application.find(@current_user.application.id)
      @auth_sessions = @user.auth_sessions.order(updated_at: :desc)
      @auth_sessions_total = @auth_sessions.count
      @auth_sessions = @auth_sessions.page(params[:page])
      @chat_rooms = @user.chat_rooms
      
      @path_segments = request.fullpath.split("/")

      render "index"
    rescue => e
      flash[:notice] = e.message
      redirect_to '/dashboard/user/home'
    end
  end

end