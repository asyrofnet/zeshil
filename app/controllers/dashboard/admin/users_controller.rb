class Dashboard::Admin::UsersController < AdminController
  before_action :authorize_admin

  # template dashboard/admin/users/index
  def index
    begin
      @application = ::Application.find(@current_admin.application.id)
      @users = @application.users.includes(:roles).order(created_at: :desc)
      @users_count = @users.count

      if params[:search].present?
        @users = @users.where("LOWER(phone_number) LIKE ?", "%#{params['phone_number'].downcase}%") if params[:phone_number].present?
        @users = @users.where("LOWER(fullname) LIKE ?", "%#{params['fullname'].downcase}%") if params[:fullname].present?
      else
        @users = @users.page(params[:page])
      end

      @path_segments = request.fullpath.split("/")

      render "index"
    rescue Exception => e
      flash[:notice] = e.message
      redirect_to '/dashboard/admin/home'
    end
  end

  def list_sessions
    begin
      @path_segments = request.fullpath.split("/")

      @application = ::Application.find(@current_admin.application.id)

      sql = %{
        SELECT
          u.id,
          u.fullname,
          u.phone_number,
          u.email,
          auth_count.count AS sessions_count,
          last_session.updated_at AS last_session
        FROM users AS u
        LEFT JOIN
        (
          SELECT
            user_id,
            MAX(updated_at) as updated_at
          FROM auth_sessions
          GROUP BY user_id
          ORDER BY updated_at DESC
        ) AS last_session
        ON last_session.user_id = u.id
        LEFT JOIN
        ( SELECT
            user_id,
            count(user_id) AS count
          FROM auth_sessions
          GROUP BY user_id
        ) AS auth_count
        ON auth_count.user_id = u.id
        WHERE u.application_id = #{@application.id} AND auth_count.count > 0
        ORDER BY auth_count.count DESC
      }

      user_sessions = ActiveRecord::Base.connection.execute(sql)
      @users = user_sessions.entries

      # using kaminari to paginate an array (@users)
      @users = Kaminari.paginate_array(@users).page(params[:page]).per(25)

      render "list_sessions"

    rescue Exception => e
      flash[:notice] = e.message
      redirect_to '/dashboard/admin/home'
    end
  end

  def show
    begin
      @user = User.find_by(id: params[:id], application_id: @current_admin.application.id)

      if @user.nil?
        flash[:notice] = "User not found"
        redirect_to '/dashboard/admin/home' and return
      end

      @application = ::Application.find(@current_admin.application.id)
      @auth_sessions = @user.auth_sessions.order(updated_at: :desc)
      @auth_sessions_total = @auth_sessions.count
      @auth_sessions = @auth_sessions.page(params[:page])
      @chat_rooms = @user.chat_rooms
      @user_roles_id = @user.roles.pluck(:id)

      @user_features_id = @user.features.pluck(:id)

      @path_segments = request.fullpath.split("/")

      render "show"
    rescue Exception => e
      flash[:notice] = e.message
      redirect_to '/dashboard/admin/home'
    end
  end

  def update
    begin
      @user = User.find_by(id: params[:user_id], application_id: @current_admin.application.id)
      user_params = params.permit!

      # use if clause to update phone_number, fullname, email, gender, date of birth and is public only
      # this will avoid user to update another unpermitted column such as qiscus email or qiscus token
      phone_number = user_params[:phone_number]
      if phone_number.present? && !phone_number.nil? && phone_number != ""
        phone_number = phone_number.strip().delete(' ')
        # phone_number = PhonyRails.normalize_number(phone_number, default_country_code: 'ID') # normalize phone number

        # before updating user's email or phone number, check if there are no another user
        # who have same email/phone number except current user
        if User.where.not(id: @user.id).where(application_id: @user.application.id).exists?(phone_number: phone_number)
          raise Exception.new("Your submitted phone number already used by another user. Please use another phone number.")
        end

        @user.phone_number = phone_number
      end

      # secondary phone number for buddygo support
      secondary_phone_number = user_params[:secondary_phone_number]
      if secondary_phone_number.present? && !secondary_phone_number.nil? && secondary_phone_number != ""
        secondary_phone_number = secondary_phone_number.strip().delete(' ')
        @user.secondary_phone_number = secondary_phone_number
      end

      country_code = user_params[:country_code]
      if country_code.present? && !country_code.nil? && country_code != ""
        if !@user.phone_number.include? country_code
          raise Exception.new("You have to include your validated country code at the beginning of your phone_number")
        else
          @user.country_code = country_code.strip().delete(' ')
        end
      end

      fullname = user_params[:fullname]
      if fullname.present? && !fullname.nil? && fullname != ""
        @user.fullname = (fullname.nil? || fullname == "") ? "" : fullname.strip().gsub(/\s+/, " ") # to remove multi space to single space
      end

      email = user_params[:email]
      if email.present? && !email.nil? && email != ""
        # before updating user's email or phone number, check if there are no another user
        # who have same email/phone number except current user
        if User.where.not(id: @user.id).where(application_id: @user.application.id).exists?(email: email)
          raise Exception.new("Your submitted email already used by another user. Please use another email.")
        end

        @user.email = (email.nil? || email == "") ? "" : email.strip().delete(' ')
      end

      gender = user_params[:gender]
      if gender.present? && !gender.nil? && gender != ""
        @user.gender = gender
      end

      date_of_birth = user_params[:date_of_birth]
      if date_of_birth.present? && !date_of_birth.nil? && date_of_birth != ""
        @user.date_of_birth = date_of_birth
      end

      is_public = user_params[:is_public]
      if is_public.present?
        if is_public == "on"
          @user.is_public = true
        else

          @user.is_public = false
        end
      end

      description = user_params[:description]
      if description.present? && !description.nil? && description != ""
        @user.description = description
      end

      callback_url = user_params[:callback_url]
      @user.callback_url = callback_url

      @avatar_file = params[:avatar_file]
      if @avatar_file.present?
        qiscus_sdk = QiscusSdk.new(@user.application.app_id, @user.application.qiscus_sdk_secret)
        url = qiscus_sdk.upload_file(@user.qiscus_token, @avatar_file)
        @user.avatar_url = url
      end

      role_ids = user_params[:roles]
      if role_ids.present?
        # If app connected to coaching module, it can't add Official Account roles
        application = @current_admin.application
        if application.is_coaching_module_connected
          if role_ids.to_a.map(&:to_i).include? Role.official.id
            raise Exception.new("Access denied. Cannot add Official Account roles.")
          end
        end

        @user.roles = Role.where("id IN (?)", role_ids.to_a.map(&:to_i))
      end

      @user.save!

      # Update SDK Profile if fullname or avatar_file present
      if fullname.present? || @avatar_file.present?
        user = User.find_by(id: params[:user_id], application_id: @current_admin.application.id)
        qiscus_sdk = QiscusSdk.new(user.application.app_id, user.application.qiscus_sdk_secret)
        qiscus_token = qiscus_sdk.update_profile(user.qiscus_email, user.fullname, user.avatar_url)
      end

      flash[:success] = "Success update profile."
      redirect_back fallback_location: '/dashboard/admin/home' and return
    rescue Exception => e
      # render json: {
      #   backtrace: e.backtrace
      # } and return
      flash[:notice] = e.message
      redirect_back fallback_location: '/dashboard/admin/home'
    end
  end

  def delete
    begin
      @user = User.find_by(id: params[:id], application_id: @current_admin.application.id)
      application = Application.find(@current_admin.application.id)

      if @user.nil?
        flash[:notice] = "User not found"
        redirect_to '/dashboard/admin/home' and return
      end

      ActiveRecord::Base.transaction do
        chat_rooms = @user.chat_rooms
        # is that user has a "group" chat?
        chat_rooms = chat_rooms.where(is_group_chat: true)

        if chat_rooms.nil?
          # if no, its ok. nothing to do. just remove the user.
          @user.destroy
        else
          # if yes, remove that user from groups
          qiscus_room_ids = chat_rooms.pluck(:qiscus_room_id)
          user_ids = []

          # insert @user to array
          chat_rooms.each do |chat_room|
            user_id = chat_room.chat_users.where(user_id: @user.id).pluck(:user_id)
            user_ids.push(user_id)
          end

          # background job for remove user from group
          RemoveGroupParticipantsJob.perform_later(application.id, qiscus_room_ids, user_ids)
          # delete user from qisme
          @user.destroy

          # manage group admin. if there is no admin in the rooms left by @user,
          # make the first participants as admin
          chat_rooms.each do |chat_room|
            group_admin_count = chat_room.chat_users.where(is_group_admin: true).count
            if group_admin_count == 0
              chat_user = chat_room.chat_users.first
              chat_user.update_attribute(:is_group_admin, true)
            end
          end
        end
      end

      flash[:success] = "Success delete profile '#{@user.fullname || @user.phone_number || @user.email}'."
      redirect_to "/dashboard/admin/users"
    rescue Exception => e
      flash[:notice] = e.message
      redirect_to '/dashboard/admin/home'
    end
  end

  def new
    render "new"
  end

  def create
    begin
      application = nil
      user = nil
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

        # If app connected to coaching module, It can't add Official Account roles
        application = @current_admin.application
        if application.is_coaching_module_connected
          if params[:user_roles].to_a.map(&:to_i).include? Role.official.id
            raise Exception.new("Access denied. Cannot add Official Account roles.")
          end
        end


        # check if user already exist or not
        phone_number = params[:user][:phone_number]
        if phone_number.nil? != false || phone_number != ""
          phone_number = phone_number.strip().delete(' ')
          # phone_number = PhonyRails.normalize_number(phone_number, default_country_code: 'ID')

          if phone_number == ""
            raise Exception.new('Phone number is empty.')
          end
        else
          raise Exception.new('Phone number is empty.')
        end
        user = User.find_by(phone_number: phone_number, application_id: application.id)

        # if nil then register
        if user.nil?
          new_user_credential = params[:user].permit!

          email_sdk = params[:user][:phone_number].tr('+', '').delete(' ')
          email_sdk = email_sdk.downcase.gsub(/[^a-z0-9_.]/i, "") # only get alphanumeric and _ and . string only
          email_sdk = email_sdk + "@" + application.app_id + ".com" # will build string like 085868xxxxxx@app_id.com

          new_user_credential.delete(:app_id) # delete app id, replace with application_id
          new_user_credential["application_id"] = application.id
          new_user_credential["qiscus_token"] = "qiscus_token"
          new_user_credential["qiscus_email"] = email_sdk
          new_user_credential["phone_number"] = phone_number

          # check is parameter country code presence or not
          # if yes, we will use it as user's country code.
          # if not, we will assuming the first 3 digits is country code
          country_code = params[:user][:country_code]
          if country_code.present?
            if !phone_number.include? country_code
              raise Exception.new("You have to include your validated country code at the beginning of your phone_number")
            else
              new_user_credential["country_code"] = country_code.strip().delete(' ')
            end
          else
            new_user_credential["country_code"] = phone_number.slice(0..2)
          end

          # render json: {new_user_credential: new_user_credential} and return

          # using class initiation to avoid user send another params (i.e fullname and it is saved)
          official_role_id = [Role.official.id.to_s]
          username_valid = UserAdditionalInfo.check_username(new_user_credential["username"])
          
          if (params[:user_roles] - official_role_id != params[:user_roles]) && (username_valid[:success] != true)
            raise Exception.new("username is invalid!")
          end
          user = User.new
          user.phone_number = new_user_credential["phone_number"]
          user.fullname = new_user_credential["fullname"]
          user.application_id = new_user_credential["application_id"]
          user.qiscus_token = new_user_credential["qiscus_token"]
          user.qiscus_email = new_user_credential["qiscus_email"]
          user.email = new_user_credential["email"]
          user.gender = new_user_credential["gender"]
          user.date_of_birth = new_user_credential["date_of_birth"]
          user.description = new_user_credential["description"]
          user.callback_url = new_user_credential["callback_url"]
          user.is_public = false
          user.country_code = new_user_credential["country_code"]

          if params[:user_roles].to_a.empty?
            raise Exception.new("You must select roles!")
          end

          user.roles = Role.where("id IN (?)", params[:user_roles].to_a)
          ActiveRecord::Base.transaction do
            if (user.save!) && (params[:user_roles] - official_role_id != params[:user_roles])
              if username_valid[:success] == true
                additional_info = UserAdditionalInfo.new
                additional_info.key = "username"
                additional_info.value = new_user_credential["username"]
                additional_info.user_id = user.id
                additional_info.save!
              end
            end
          end

          # Backend no need to register user in SDK (but if it's okay even it is happen (for easy debugging when trying qisus chat room))
          # add user id to email to ensure that email is really unique
          email_sdk = "userid_" + user.id.to_s + "_" + user.qiscus_email
          qiscus_sdk = QiscusSdk.new(application.app_id, application.qiscus_sdk_secret)
          # keep "password" for backward compatibility
          qiscus_token = qiscus_sdk.login_or_register_rest(email_sdk, "password", user.fullname) # get qiscus token

          # this ensure qiscus email sdk to be unique
          user.update_attribute(:qiscus_email, email_sdk)
          user.update_attribute(:qiscus_token, qiscus_token)

          avatar_file = new_user_credential["avatar_file"]
          if avatar_file.present?
            url = qiscus_sdk.upload_file(qiscus_token, avatar_file)
            user.update!(avatar_url: url)
          end
        else
          raise Exception.new('User with given phone number already exist.')
        end

        # here the user must already created, so we can add default contact (official user) here
        role_official_user = Role.official
        if role_official_user.nil? == false
          user_role_ids = UserRole.where(role_id: role_official_user.id).pluck(:user_id).to_a
          official_account = User.where("id IN (?)", user_role_ids).where(application_id: application.id)

          official_account.each do |oa|
            contact = Contact.find_by(user_id: user.id, contact_id: oa.id)

            if contact.nil?
              contact = Contact.new
              contact.user_id = user.id
              contact.contact_id = oa.id
              contact.save
            end
          end
        end
      end

      # render json: {
      #   data: user
      # } and return
      flash[:success] = "New user created!"
      redirect_to "/dashboard/admin/users/#{user.id}"

    rescue ActiveRecord::RecordInvalid => e
      flash[:notice] = e.message
      redirect_back fallback_location: '/dashboard/admin/home'

    rescue Exception => e
      flash[:notice] = e.message
      redirect_back fallback_location: '/dashboard/admin/home'
    end
  end

  def activity
    begin
      @user = User.find_by(id: params[:user_id])

      if @user.nil?
        flash[:notice] = "User not found"
        redirect_to '/dashboard/admin/home' and return
      end

      @application = ::Application.find(@current_admin.application.id)
      @auth_sessions = @user.auth_sessions.order(updated_at: :desc)
      @auth_sessions = @auth_sessions.page(params[:page])
      @chat_rooms = @user.chat_rooms.order(updated_at: :desc)
      @user_roles_id = @user.roles.pluck(:id)

      @path_segments = request.fullpath.split("/")

      render "activity"
      # render json: {
      #   user: @chat_rooms
      # }
    rescue Exception => e
      flash[:notice] = e.message
      redirect_to '/dashboard/admin/home'
    end
  end

  # for update user features
  # post /dashboard/admin//users/4/update_features
  def update_features
    begin
      @user = User.find_by(id: params[:id], application_id: @current_admin.application.id)
      user_params = params.permit!


      feature_ids = user_params[:features]
      @user.features = Feature.where("id IN (?)", feature_ids.to_a.map(&:to_i))

      @user.save!

      flash[:success] = "Success update user features."
      redirect_back fallback_location: '/dashboard/admin/home' and return
    rescue Exception => e
      render json: {
        backtrace: e.backtrace
      } and return
      flash[:notice] = e.message
      redirect_back fallback_location: '/dashboard/admin/home'
    end
  end

  # for create room with unique id
  # post /dashboard/admin/users/4/create_room_with_unique_id
  def create_room_with_unique_id
    begin
      chat_room = nil
      ActiveRecord::Base.transaction do
        @user = User.find_by(id: params[:id], application_id: @current_admin.application.id)
        application = @user.application
        qiscus_token = @user.qiscus_token

        # Genereate unique_id
        # Unique id is combination of app_id, creator (official) qiscus_email, app_id using # as separator. For example unique_id = "kiwari-prod#userid_001_62812345678987@kiwari-prod.com#kiwari-prod
        unique_id = "#{application.app_id}##{@user.qiscus_email}##{application.app_id}"

        # Ensure that public chat room is not exist
        chat_room = ChatRoom.find_by(user_id: @user.id, is_public_chat: true, application_id: application.id)
        if !chat_room.nil?
          flash[:notice] = "Public chat already exist."
          redirect_to "/dashboard/admin/users/#{@user.id}/activity" and return
        end

        chat_name = @user.fullname
        chat_avatar_url = @user.avatar_url

        # Backend need to create chat room with unique id in SDK
        qiscus_sdk = QiscusSdk.new(application.app_id, application.qiscus_sdk_secret)
        room = qiscus_sdk.get_or_create_room_with_unique_id(qiscus_token, unique_id, chat_name, chat_avatar_url)

        qiscus_room_id = room.id

        chat_room = ChatRoom.find_by(qiscus_room_id: qiscus_room_id, application_id: @user.application.id)

        if chat_room.nil?
          chat_room = ChatRoom.new(
            group_chat_name: chat_name,
            qiscus_room_name: chat_name,
            qiscus_room_id: qiscus_room_id,
            is_group_chat: true,
            user_id: @user.id,
            target_user_id: @user.id,
            application_id: @user.application.id,
            group_avatar_url: chat_avatar_url,
            is_official_chat: false,
            is_public_chat: true
          )

          chat_room.save!

          chat_user = ChatUser.new
          chat_user.chat_room_id = chat_room.id
          chat_user.user_id = @user.id
          chat_user.is_group_admin = true # group creator assign as group admin
          chat_user.save!

          # Backend need to post system event message after room_created
          # Post system event message with system_event_type = create_room
          system_event_type = "create_room"
          qiscus_sdk = QiscusSdk.new(application.app_id, application.qiscus_sdk_secret)
          qiscus_sdk.post_system_event_message(system_event_type, qiscus_room_id, @user.qiscus_email, [], chat_name)
        end
      end

      flash[:success] = "New public chat created!"
      redirect_to "/dashboard/admin/users/#{@user.id}/activity"

    rescue ActiveRecord::RecordInvalid => e
      msg = ""
      e.record.errors.map do |k, v|
        key = k.to_s.humanize
        msg = msg + "#{key} #{v}, "
      end

      msg = msg.chomp(", ") + "."
      flash[:notice] = msg
      redirect_back fallback_location: '/dashboard/admin/home'

    rescue Exception => e
      flash[:notice] = e.message
      redirect_back fallback_location: '/dashboard/admin/home'
    end
  end

  def export
    begin
      @application = ::Application.find(@current_admin.application.id)
      @users = @application.users.includes(:roles).order(created_at: :desc)

    rescue Exception => e
      flash[:notice] = e.message
      redirect_to '/dashboard/admin/home'
    end
  end

  def post_export
    begin
			start_date = params[:start_date]
			end_date = params[:end_date]
      @application = ::Application.find(@current_admin.application.id)
      @users = @application.users.includes(:roles).where(:created_at => start_date..end_date).order(created_at: :desc)

			file = "#{Rails.root}/public/users.csv"
			header = ["fullname", "phone_number", "email", "gender", "date_of_birth", "roles", "created_at"]

			CSV.open( file, 'w' ) do |writer|
				writer << header
				@users.each do |u|
					writer << [u.fullname, u.phone_number, u.email, u.gender, u.date_of_birth, u.roles.pluck(:name).join(" ") , u.created_at]
				end
			end

			filename = "#{@application.app_id}-users-#{Date.today}.csv"
			send_file file,
				:type => 'text/csv; charset=iso-8859-1; header=present',
				:disposition => "attachment; filename=#{filename}",
				:stream => true,
				:buffer_size => 4096

    rescue Exception => e
      flash[:notice] = e.message
      redirect_to '/dashboard/admin/home'
    end
  end

  def export_list_sessions
    begin
			@application = ::Application.find(@current_admin.application.id)

      sql = %{
        SELECT
          u.id,
          u.fullname,
          u.phone_number,
          u.email,
          auth_count.count AS sessions_count,
          last_session.updated_at AS last_session
        FROM users AS u
        LEFT JOIN
        (
          SELECT
            user_id,
            MAX(updated_at) as updated_at
          FROM auth_sessions
          GROUP BY user_id
          ORDER BY updated_at DESC
        ) AS last_session
        ON last_session.user_id = u.id
        LEFT JOIN
        ( SELECT
            user_id,
            count(user_id) AS count
          FROM auth_sessions
          GROUP BY user_id
        ) AS auth_count
        ON auth_count.user_id = u.id
        WHERE u.application_id = #{@application.id} AND auth_count.count > 0
        ORDER BY auth_count.count DESC
      }

      user_sessions = ActiveRecord::Base.connection.execute(sql)
      @users = user_sessions.entries

      file = "#{Rails.root}/public/list_user_sessions.csv"
      header = ["fullname", "phone_number", "email", "sessions_count", "last_session"]

      CSV.open( file, 'w' ) do |writer|
        writer << header
        @users.each do |u|
          writer << [u['fullname'], u['phone_number'], u['email'], u['sessions_count'], u['last_session'].in_time_zone("Asia/Jakarta")]
        end
      end

      filename = "#{@application.app_id}-list-user-sessions-#{Date.today}.csv"
      send_file file,
        :type => 'text/csv; charset=iso-8859-1; header=present',
        :disposition => "attachment; filename=#{filename}",
        :stream => true,
        :buffer_size => 4096

    rescue Exception => e
      flash[:notice] = e.message
      redirect_to '/dashboard/admin/home'
    end
  end

end
