require 'jwt'

module UserSessionHelper

  def authorize_user
    begin
      @current_user = User.find_by(id: session[:user_id])

      if @current_user.nil?
        redirect_back fallback_location: ""
      end

      return true
    rescue Exception => e
      redirect_back fallback_location: ""
    end
  end
end
