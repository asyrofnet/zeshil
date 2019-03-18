class Dashboard::Admin::HomeController < AdminController
  before_action :authorize_admin

  # template dashboard/admin/home/index
  def index
    begin
      @application = ::Application.find(@current_admin.application.id)

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
      render "index"
    rescue Exception => e
      flash[:notice] = e.message
      redirect_back fallback_location: '/dashboard/admin/home'
    end
  end

  def make_all_users_as_contact
    begin

      MakeAllUsersAsContact.perform_later(@current_admin.application.id)

      flash[:success] = "Make all users as contact is on progress"
      redirect_back fallback_location: '/dashboard/admin/home' and return
    rescue Exception => e
      flash[:notice] = e.message
      redirect_back fallback_location: '/dashboard/admin/home'
    end
  end

end
