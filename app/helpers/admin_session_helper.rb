require 'jwt'

module AdminSessionHelper

  def authorize_admin
    begin
      @current_admin = User.find_by(id: session[:current_user_id])

      if @current_admin.nil?
        redirect_back fallback_location: ""
      end

      return true
    rescue Exception => e
      redirect_back fallback_location: ""
    end
  end
end
