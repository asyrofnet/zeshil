class Format < ActiveRecord::Base
  def self.get_os_request(request)
    if request.user_agent.downcase.match(/android/)
      @os = "android"
    elsif request.user_agent.downcase.match(/iphone|ipad/)
      @os = "ios"
    elsif request.user_agent.downcase.match(/mac|windows|linux/)
      @os = "desktop"
    end
    return @os
  end

end