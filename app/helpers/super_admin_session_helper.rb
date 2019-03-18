require 'jwt'

module SuperAdminSessionHelper

  def authorize_super_admin
    begin
      if session[:superuser] == 'super'
        return true
      else
        redirect_to dashboard_auth_index_path and return
      end
    rescue Exception => e
      redirect_to dashboard_auth_index_path and return
    end
  end
end
