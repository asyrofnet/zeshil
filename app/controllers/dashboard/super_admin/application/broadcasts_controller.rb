class Dashboard::SuperAdmin::Application::BroadcastsController < SuperAdminController
  before_action :authorize_super_admin

  def index
    begin
      @application = ::Application.find(params[:application_id])

      role_official_user = ::Role.official
      user_role_ids = ::UserRole.where(role_id: role_official_user.id).pluck(:user_id).to_a
      @official_users = ::User.where("id IN (?)", user_role_ids).where(application_id: @application.id)

      @users = @application.users.order(created_at: :desc)
      @users = @users.where.not(fullname: nil).where.not(fullname: "")
      @users = @users - @official_users

      @path_segments = request.fullpath.split("/")

      render "index"
    rescue => e
      flash[:notice] = e.message
      redirect_to '/dashboard/super_admin/home'
    end
  end

  def show_chat_users
    begin
      @application = ::Application.find(params[:application_id])
      role_official_user = ::Role.official
      user_role_ids = ::UserRole.where(role_id: role_official_user.id).pluck(:user_id).to_a
      @official_users = ::User.where("id IN (?)", user_role_ids).where(application_id: params[:application_id])

      @users = @application.users.order(created_at: :desc)
      @users = @users.where.not(fullname: nil).where.not(fullname: "")
      @users = @users - @official_users

      @path_segments = request.fullpath.split("/")

      render "show_chat_users"
    rescue => e
      flash[:notice] = e.message
      redirect_to '/dashboard/super_admin/home'
    end
  end

  def show_users
    begin
      sender_user_id = params[:sender_user_id]
      sender_user = User.find(sender_user_id)

      chat_rooms = sender_user.chat_rooms
      chat_rooms = chat_rooms.where(is_group_chat: false)

      user_ids = chat_rooms.pluck(:user_id)
      target_user_ids = chat_rooms.pluck(:target_user_id)
      user_ids = user_ids + target_user_ids
      user_ids.delete(sender_user.id)

      @users = ::User.where("id IN (?)", user_ids).where(application_id: params[:application_id])

      render 'show_users', layout: false and return
    rescue => e
      flash[:notice] = e.message
      redirect_back fallback_location: "/dashboard/super_admin/home"
    end
  end

  def show_status
    begin
      @application = ::Application.find(params[:application_id])
      @broadcast_messages = ::BroadcastMessage.includes(:user).where(application_id: @application.id).order('broadcast_messages.id DESC')

      @broadcast_messages_count = @broadcast_messages.count
      @broadcast_messages = @broadcast_messages.page(params[:page]).per(10)

      @path_segments = request.fullpath.split("/")

      render "show_status"
    rescue => e
      flash[:notice] = e.message
      redirect_to '/dashboard/super_admin/home'
    end
  end

  def show_receipt_histories
    begin
      @application = ::Application.find(params[:application_id])
      broadcast_message_id = params[:broadcast_message_id]
      status = params[:status]
      receipt_histories = ::BroadcastReceiptHistory.includes(:user).where(broadcast_message_id: broadcast_message_id)

      if status == "pending"
        @receipt_histories = receipt_histories.where(delivered_at: nil).where(read_at: nil)
      elsif status == "delivered"
        @receipt_histories = receipt_histories.where.not(delivered_at: nil).where(read_at: nil)
      elsif status == "read"
        @receipt_histories = receipt_histories.where.not(read_at: nil)
      end

      @receipt_histories_count = @receipt_histories.count
      @receipt_histories = @receipt_histories.page(params[:page])

      @path_segments = request.fullpath.split("/")

      render "show_receipt_histories"
    rescue => e
      flash[:notice] = e.message
      redirect_to '/dashboard/super_admin/home'
    end
  end

  def create
    begin
      sender_user_id = params[:sender_user_id]
      if sender_user_id == "" || sender_user_id.nil?
        raise InputError.new("Sender user can't be empty.")
      end
      sender_user = User.find_by(id: sender_user_id, application_id: params[:application_id])
      if sender_user.nil?
        raise InputError.new("Sender user not found.")
      end

      message = params[:message]
      if message == "" || message.nil?
        raise InputError.new("Message can't be empty.")
      end

      target_user_ids = params[:target_user_ids]
      if target_user_ids == "" || target_user_ids.nil?
        raise InputError.new("Target user can't be empty.")
      end

      target_user_ids = target_user_ids.split(",") # Split params target_user_id and convert it to array

      if !target_user_ids.is_a?(Array)
        raise InputError.new("Target user id must be an array of user id.")
      end
      target_user_ids.delete(sender_user_id) # ensure that sender user id not in target_user_ids
      target_user_ids.uniq

      target_user_emails = User.where(id:target_user_ids).pluck(:qiscus_email)

      # insert broadcast message into db
      broadcast_message = BroadcastMessage.new(
        user_id: sender_user_id,
        message: message,
        application_id: params[:application_id]
      )

      broadcast_message.save!
      type = "text"
      payload = nil
      # send broadcast message in background job
      BroadcastMessageJobV2.perform_later(sender_user, target_user_emails, message,type,payload ,broadcast_message.id)

      flash[:success] = "Sending broadcast message is on progress."

      redirect_to "/dashboard/super_admin/application/#{params[:application_id]}/broadcasts" and return
    rescue => e
      flash[:notice] = e.message
      redirect_back fallback_location: "/dashboard/super_admin/application/#{params[:application_id]}/broadcasts"
    end
  end

end