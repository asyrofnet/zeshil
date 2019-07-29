class Format < ActiveRecord::Base
  def self.get_os_request(request)
    if request.user_agent.downcase.match(/android/)
      @os = "android"
    elsif request.user_agent.downcase.match(/iphone|ipad|ios/)
      @os = "ios"
    elsif request.user_agent.downcase.match(/mac|windows|linux/)
      @os = "desktop"
    end
    return @os
  end

  def self.get_ios_build_number(request)
    user_agent = request.user_agent
    build_start = user_agent.index("build")
    subs_build = user_agent[build_start..build_start+11]
    start_sub = subs_build.index(":")
    end_sub = subs_build.index(";")
    subs_number = subs_build[start_sub+1..end_sub-1]
    subs_number = subs_number.gsub(/\s+/, "")
    return subs_number 
  end

  def self.get_ios_version_number(request)
    user_agent = request.user_agent
    version_start = user_agent.index("iwari/")+"iwari/".length
    subs_build = user_agent[version_start..version_start+6]
    start_sub = 0
    end_sub = subs_build.index("(") || subs_build.length
    subs_number = subs_build[start_sub..end_sub-1]
    subs_number = subs_number.gsub(/\s+/, "")
    return subs_number 
  end

end