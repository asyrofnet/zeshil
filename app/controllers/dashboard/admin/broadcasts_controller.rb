class Dashboard::Admin::BroadcastsController < AdminController
  before_action :authorize_admin

  def index
    begin
      application = @current_admin.application
      role_official_user = ::Role.official
      user_role_ids = ::UserRole.where(role_id: role_official_user.id).pluck(:user_id).to_a
      @official_users = ::User.where("id IN (?)", user_role_ids).where(application_id: application.id)

      @users = application.users.order(created_at: :desc)
      @users = @users.where.not(fullname: nil).where.not(fullname: "")
      @users = @users - @official_users

      @path_segments = request.fullpath.split("/")

      render "index"
    rescue => e
      flash[:notice] = e.message
      redirect_to '/dashboard/admin/home'
    end
  end

  def show_chat_users
    begin
      application = @current_admin.application
      role_official_user = ::Role.official
      user_role_ids = ::UserRole.where(role_id: role_official_user.id).pluck(:user_id).to_a
      @official_users = ::User.where("id IN (?)", user_role_ids).where(application_id: application.id)

      @users = application.users.order(created_at: :desc)
      @users = @users.where.not(fullname: nil).where.not(fullname: "")
      @users = @users - @official_users

      @path_segments = request.fullpath.split("/")

      render "show_chat_users"
    rescue => e
      flash[:notice] = e.message
      redirect_to '/dashboard/admin/home'
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

      @users = ::User.where("id IN (?)", user_ids).where(application_id: @current_admin.application.id)

      render 'show_users', layout: false and return
    rescue => e
      flash[:notice] = e.message
      redirect_back fallback_location: "/dashboard/admin/home"
    end
  end

  def show_status
    begin
      application = @current_admin.application
      @broadcast_messages = ::BroadcastMessage.includes(:user).where(application_id: application.id).order('broadcast_messages.id DESC')

      @broadcast_messages_count = @broadcast_messages.count
      @broadcast_messages = @broadcast_messages.page(params[:page]).per(10)

      @path_segments = request.fullpath.split("/")

      render "show_status"
    rescue => e
      flash[:notice] = e.message
      redirect_to '/dashboard/admin/home'
    end
  end

  def show_receipt_histories
    begin
      application = @current_admin.application
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
      redirect_to '/dashboard/admin/home'
    end
  end

  def create
    begin
      sender_user_id = params[:sender_user_id]
      if sender_user_id == "" || sender_user_id.nil?
        raise StandardError.new("Sender user can't be empty.")
      end

      message = params[:message]
      if message == "" || message.nil?
        raise StandardError.new("Message can't be empty.")
      end

      target_user_ids = params[:target_user_ids]
      if target_user_ids == "" || target_user_ids.nil?
        raise StandardError.new("Target user can't be empty.")
      end

      target_user_ids = target_user_ids.split(",") # Split params target_user_id and convert it to array

      if !target_user_ids.is_a?(Array)
        raise StandardError.new("Target user id must be an array of user id.")
      end
      target_user_ids.delete(sender_user_id) # ensure that sender user id not in target_user_ids
      target_user_ids.uniq

      # insert broadcast message into db
      broadcast_message = BroadcastMessage.new(
        user_id: sender_user_id,
        message: message,
        application_id: @current_admin.application.id
      )

      broadcast_message.save!

      # send broadcast message in background job
      BroadcastMessageJob.perform_later(sender_user_id, target_user_ids, message, broadcast_message.id)

      flash[:success] = "Sending broadcast message is on progress."
      redirect_to "/dashboard/admin/broadcasts" and return

    rescue => e
      flash[:notice] = e.message
      redirect_back fallback_location: "/dashboard/admin/broadcasts"
    end
  end
end
