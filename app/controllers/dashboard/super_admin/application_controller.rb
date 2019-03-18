class Dashboard::SuperAdmin::ApplicationController < SuperAdminController
  before_action :authorize_super_admin

  def index
    redirect_to "/dashboard/super_admin/home"
  end

  # template dashboard/super_admin/application/new
  def new
    @application = ::Application.all.order(created_at: :desc)
    render 'new'
  end

  def create
    begin
      app_name = params[:app_name]
      if app_name == "" || app_name.nil?
        raise Exception.new("app_name can't be empty.")
      end

      # check app_name character because qiscus sdk only allow app_name in alphabet
      is_all_alphabet = app_name[/[a-zA-Z ]+/] == app_name
      if is_all_alphabet == false
        raise Exception.new("app_name only alphabet are allowed.")
      end

      # Create new app in Qiscus SDK using QIscus SDK Admin API
      qiscus_sdk_admin = QiscusSdkAdmin.new()
      qiscus_app_id, qiscus_secret_key = qiscus_sdk_admin.create_app(app_name)

      application = nil
      ActiveRecord::Base.transaction do
        application = Application.new
        application.app_id = qiscus_app_id
        application.qiscus_sdk_secret = qiscus_secret_key
        application.app_name = app_name
        application.description = params[:description]
        application.qiscus_sdk_url = "https://" + qiscus_app_id + ".qiscus.com"
        application.sms_sender = params[:sms_sender]
        application.server_key = params[:server_key]
        application.fcm_key = params[:fcm_key]
        application.apns_cert_dev = params[:apns_cert_dev]
        application.apns_cert_prod = params[:apns_cert_prod]
        application.apns_cert_topic = params[:apns_cert_topic]
        application.apns_cert_password = params[:apns_cert_password]
        application.is_auto_friend = params[:is_auto_friend]
        application.is_send_message_pn = params[:is_send_message_pn]
        application.is_send_call_pn = params[:is_send_call_pn]
        application.is_coaching_module_connected = params[:is_coaching_module_connected]

        # add sms provider
        application.save_and_add_provider_setting_data(application)
      end

      flash[:success] = "Success create new application #{is_all_alphabet}."
      redirect_to '/dashboard/super_admin/home' and return
    rescue Exception => e
      flash[:notice] = e.message
      redirect_back fallback_location: '/dashboard/super_admin/home'
    end
  end

  def show
    begin
      @application = ::Application.find(params[:id])

      users = @application.users
      per_month = users.group("DATE_TRUNC('month', users.created_at)").order("DATE_TRUNC('month', users.created_at)").count

      # user per month register
      user_per_month = Array.new
      per_month.each do |k, v|
        tmp = Hash.new
        tmp["month"] = k.strftime('%b %Y')
        tmp["total_user"] = v

        user_per_month.push(tmp)
      end

      # chat room
      chat_room = ChatRoom.where(application_id: @application.id)
      chat_per = chat_room.group("DATE_TRUNC('month', chat_rooms.created_at)").order("DATE_TRUNC('month', chat_rooms.created_at)").count

      chat_per_month = Array.new
      chat_per.each do |k, v|
        tmp = Hash.new
        tmp["month"] = k.strftime('%b %Y')
        tmp["total"] = v

        chat_per_month.push(tmp)
      end

      chat_group_per = chat_room.group("DATE_TRUNC('month', chat_rooms.created_at)").order("DATE_TRUNC('month', chat_rooms.created_at)").where(is_group_chat: true).count

      group_chat_per_month = Array.new
      chat_group_per.each do |k, v|
        tmp = Hash.new
        tmp["month"] = k.strftime('%b %Y')
        tmp["total"] = v

        group_chat_per_month.push(tmp)
      end

      chat_single_per = chat_room.group("DATE_TRUNC('month', chat_rooms.created_at)").order("DATE_TRUNC('month', chat_rooms.created_at)").where(is_group_chat: false).count

      single_chat_per_month = Array.new
      chat_single_per.each do |k, v|
        tmp = Hash.new
        tmp["month"] = k.strftime('%b %Y')
        tmp["total"] = v

        single_chat_per_month.push(tmp)
      end

      @statistics = {
        data: {
          user: {
            total: users.count,
            user_register: user_per_month
          },

          chat: {
            all_total: chat_room.count,
            single_chat_total: chat_room.where(is_group_chat: false).count,
            group_chat_total: chat_room.where(is_group_chat: true).count,

            all: chat_per_month,
            group: group_chat_per_month,
            single: single_chat_per_month
          }

        }
      }

      # render json: @statistics and return
      render "show"
    rescue Exception => e
      flash[:notice] = e.message
      redirect_back fallback_location: '/dashboard/super_admin/home'
    end
  end

  def edit
    @application = ::Application.find(params[:id])
    render "edit"
  end

  def update
    begin
      application = nil
      ActiveRecord::Base.transaction do
        application = ::Application.find(params[:id])
        application.app_name = params[:app_name] if params[:app_name].present?
        application.description = params[:description] if params[:description].present?
        application.sms_sender = params[:sms_sender] if params[:sms_sender].present?
        application.server_key = params[:server_key] if params[:server_key].present?
        application.fcm_key = params[:fcm_key] if params[:fcm_key].present?
        application.apns_cert_dev = params[:apns_cert_dev] if params[:apns_cert_dev].present?
        application.apns_cert_prod = params[:apns_cert_prod] if params[:apns_cert_prod].present?
        application.apns_cert_topic = params[:apns_cert_topic] if params[:apns_cert_topic].present?
        application.apns_cert_password = params[:apns_cert_password] if params[:apns_cert_password].present?
        application.is_auto_friend = params[:is_auto_friend] if params[:is_auto_friend].present?
        application.is_send_message_pn = params[:is_send_message_pn] if params[:is_send_message_pn].present?
        application.is_send_call_pn = params[:is_send_call_pn] if params[:is_send_call_pn].present?
        application.is_coaching_module_connected = params[:is_coaching_module_connected] if params[:is_coaching_module_connected].present?
        application.save!
      end

      flash[:success] = "Success update application."
      redirect_back fallback_location: '/dashboard/super_admin/home' and return
    rescue Exception => e
      flash[:notice] = e.message
      redirect_back fallback_location: '/dashboard/super_admin/home'
    end
  end

  def delete
    begin
      application = ::Application.find_by(id: params[:id])

      if application.nil?
        raise Exception.new("Not found application.")
      end

      application.destroy

      flash[:success] = "Success delete application."
      redirect_back fallback_location: '/dashboard/super_admin/home' and return
    rescue Exception => e
      flash[:notice] = e.message
      redirect_back fallback_location: '/dashboard/super_admin/home'
    end
  end

  def mobile_version
    begin
      @application = ::Application.find(params[:id])
      @mobile_apps_version = MobileAppsVersion::where(application_id: params[:id])
      render "mobile_version"
    rescue Exception => e
      flash[:notice] = e.message
      redirect_back fallback_location: '/dashboard/super_admin/home'
    end
  end

  def mobile_version_update
    begin
      @application = ::Application.find(params[:id])

      if params[:platform].nil? || !params[:platform].present? || params[:platform] == ""
        raise Exception.new("Please specify your platform name.")
      else
        if params[:platform].downcase.delete(' ') != "android" && params[:platform].downcase.delete(' ') != "ios"
          raise Exception.new("Permitted platform is 'android' or 'ios'.")
        end
      end

      if params[:version].nil? || !params[:version].present? || params[:version] == ""
        raise Exception.new("Please specify your application version.")
      end

      app_version = MobileAppsVersion.find_by(application_id: @application.id, platform: params[:platform])

      # if nil, create a new one
      if app_version.nil?
        app_version = MobileAppsVersion.new
        app_version.application_id = @application .id
        app_version.platform = params[:platform].delete(' ').downcase
        app_version.version = Versionomy.parse(params[:version].delete(' ').downcase)

        app_version.save!
      else
        # if not nil, just update current one
        app_version.update_attribute(:version, Versionomy.parse(params[:version].delete(' ').downcase))
      end

      flash[:success] = "Success update #{app_version.platform.titleize} to #{app_version.version}."
      redirect_back fallback_location: '/dashboard/super_admin/home' and return

    rescue Exception => e
      flash[:notice] = e.message
      redirect_back fallback_location: '/dashboard/super_admin/home'
    end
  end

  def provider_setting
    begin
      @application = ::Application.find(params[:id])
			@providers = ::Provider.all
      @provider_settings = ::ProviderSetting.where(application_id: params[:id]).order(attempt: :asc)
      render "provider_setting"
    rescue Exception => e
      flash[:notice] = e.message
      redirect_back fallback_location: '/dashboard/super_admin/home'
    end
  end

  def provider_setting_update
    begin
      @application = ::Application.find(params[:id])

      provider_settings = params[:provider_settings]

      provider_settings.each do |provider_setting|
        id = provider_setting["ids"]
        provider_id = provider_setting["provider_ids"]

        ps = ProviderSetting.find(id)
        ps.update_attribute(:provider_id, provider_id)
      end

      flash[:success] = "Success update provider setting."
      redirect_back fallback_location: '/dashboard/super_admin/home' and return


    rescue Exception => e
      flash[:notice] = e.message
      redirect_back fallback_location: '/dashboard/super_admin/home'
    end
  end

  def make_all_users_as_contact
    begin
      MakeAllUsersAsContact.perform_later(params[:id])

      flash[:success] = "Make all users as contact is on progress"
      redirect_back fallback_location: '/dashboard/super_admin/home' and return
    rescue Exception => e
      flash[:notice] = e.message
      redirect_back fallback_location: '/dashboard/super_admin/home'
    end
  end

end
