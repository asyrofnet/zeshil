class Dashboard::Admin::AuthSessionsController < AdminController
  before_action :authorize_admin

  # get /dashboard/super_admin/application/2/users/4/auth_sessions/6/delete
  def delete
    begin
      @auth_session = AuthSession.find(params[:id])

      if @auth_session.nil?
        flash[:notice] = "Session not found"
        redirect_to '/dashboard/super_admin/home' and return
      end

      @auth_session.destroy

      flash[:success] = "Success revoke access login from #{@auth_session.ip_address} #{@auth_session.user_agent}'." 
      redirect_to "/dashboard/admin/users/#{params[:user_id]}"
    rescue Exception => e
      flash[:notice] = e.message
      redirect_to '/dashboard/admin/home'
    end
  end

  def create
    begin
      user = User.find(params[:user_id])
      jwt = ApplicationHelper.create_jwt_token(user, request)

      flash[:success] = "Success create new access. Your access_token = #{jwt}"
      redirect_to "/dashboard/admin/users/#{params[:user_id]}"
    rescue Exception => e
      flash[:notice] = e.message
      redirect_back fallback_location: '/dashboard/admin/home'
    end
  end

  # get /dashboard/admin/users/4/auth_sessions/delete_all
  def delete_all
    begin
      @auth_sessions = AuthSession.where(user_id: params[:user_id])

      if @auth_sessions.nil?
        flash[:notice] = "Session is empty"
        redirect_to "/dashboard/admin/users/#{params[:user_id]}"
      end

      @auth_sessions.destroy_all

      flash[:success] = "Success revoke all access." 
      redirect_to "/dashboard/admin/users/#{params[:user_id]}"
    rescue Exception => e
      flash[:notice] = e.message
      redirect_to "/dashboard/admin/home"
    end
  end

end