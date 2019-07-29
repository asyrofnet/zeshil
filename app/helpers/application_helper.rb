module ApplicationHelper

  def self.create_jwt_token(user, request = nil)
    begin
      if user.kind_of?(Integer)
        user_id = user
      elsif user.kind_of?(User)
        user_id = user.id
      else 
        raise StandardError.new("Parameter must be an user or user id.")
      end

      if User.exists?(user_id)
        jwt = JWT.encode({user_id: user_id, timestamp: Time.now}, ENV['JWT_KEY'], 'HS256')

        # save auth session
        auth_session = AuthSession.new
        auth_session.user_id = user_id
        auth_session.jwt_token = jwt

        # save request detail
        if !request.nil?
          auth_session.ip_address = request.ip
          auth_session.user_agent = request.user_agent
        end

        # try to search user location
        begin
          if !request.nil?
            geocoder = Geocoder.search(request.ip)

            city = ""
            region_code = ""
            region_name = ""
            zipcode = ""
            latitude = 0
            longitude = 0
            country_name = ""
            country_code = ""
            if !geocoder.empty?
              geocoder = geocoder.first

              city = geocoder.data['city']
              region_code = geocoder.data['region_code']
              region_name = geocoder.data['region_name']
              zipcode = geocoder.data['zipcode']
              latitude = geocoder.data['latitude']
              longitude = geocoder.data['longitude']
              country_name = geocoder.data['country_name']
              country_code = geocoder.data['country_code']

              auth_session.city = city if !city.nil?
              auth_session.region_code = region_code if !region_code.nil?
              auth_session.region_name = region_name if !region_name.nil?
              auth_session.zipcode = zipcode if !zipcode.nil?
              auth_session.latitude = latitude if !latitude.nil?
              auth_session.longitude = longitude if !longitude.nil?
              auth_session.country_name = country_name if !country_name.nil?
              auth_session.country_code = country_code if !country_code.nil?
            end
          end
        rescue => e
          # do nothing
        end

        # save auth session
        auth_session.save()

        return jwt
      else
        raise StandardError.new("User with id #{user_id} is not found.")
      end
      
    rescue => e
      raise StandardError.new(e.message)
    end
  end

end
