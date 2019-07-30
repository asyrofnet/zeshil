class Api::V1::Chat::Conversations::AdminsController < ProtectedController
  before_action :authorize_user
  before_action :ensure_eligible_access_to_chatroom

  # =begin
  # @apiVersion 1.0.0
  # @api {get} /api/v1/chat/conversations/:qiscus_room_id/admins Get Group Admins
  # @apiName GetGroupAdmins
  # @apiGroup Group Chat Admin
  #
  # @apiParam {Number} qiscus_room_id Qiscus room id
  # @apiParam {String} access_token User access token
  # =end
  def index
    begin

      user_agent = request.user_agent
      @os = Format.get_os_request(request)
      
      if @os == "ios" 
        @build_number = Format.get_ios_build_number(request).to_i
        @version_number = Format.get_ios_version_number(request)
        forbidden_110 = (278..284)
        forbidden_111 = (294..301)
        forbidden_111_1 = 1
        version_110 = "1.1.0"
        version_111 = "1.1.1"
        blocked = false
        if ( (@version_number == version_110) && forbidden_110.include?(@build_number)  ) or ( 
          (@version_number == version_111) && ( forbidden_111.include?(@build_number) || @build_number == 1)
           
        )
          blocked = true
        end
        raise InputError.new("temporarily closed") if blocked
      end
      participants = @chat_room

      chat_room_id = participants.id
      # Get user_id that assign as group admin
      group_admin_ids = ChatUser.where(chat_room_id: chat_room_id).where(is_group_admin: TRUE).pluck(:user_id)
      group_admins = User.where("id IN (?)", group_admin_ids)

      render json: {
        data: group_admins
      }
    rescue => e
      render json: {
        error: {
          message: e.message,
          class: e.class.name
        }
      }, status: 422
    end
  end

  # =begin
  # @apiVersion 1.0.0
  # @api {post} /api/v1/chat/conversations/:qiscus_room_id/admins Add Group Admins
  # @apiName AddGroupAdmins
  # @apiGroup Group Chat Admin
  #
  # @apiParam {Number} qiscus_room_id Qiscus room id
  # @apiParam {Array} [user_id[]] Array of integer of user id, e.g: `user_id[]=1&user_id[]=2`
  # @apiParam {Array} [qiscus_email[]] Array of registered qiscus email, e.g: `qiscus_email[]=userid_6_qismetest3.mailinator.com@qisme.com&qiscus_email[]=userid_5_qismetest2.mailinator.com@qisme.com`
  # @apiParam {String} access_token User access token
  # =end
  def create
    begin
      chat_room = @chat_room
      new_admin_ids = Array.new

      ActiveRecord::Base.transaction do
        user_ids_already_in_group = chat_room.users.pluck(:id).to_a
        if user_ids_already_in_group.include?(@current_user.id) == false
          raise InputError.new("You are not member of this group.")
        end

        # only admin can add new group admin
        is_group_admin = ChatUser.find_by(chat_room_id: chat_room.id, user_id: @current_user.id, is_group_admin: true)
        if is_group_admin.nil?
          raise InputError.new("You are not admin of this group. Only admin can add new group admin.")
        end

        if !params[:user_id].present? && !params[:qiscus_email].present?
          raise InputError.new("Array of user id or qiscus email must be present.")
        end

        # add group admins using array of user_id
        if params[:user_id].kind_of?(Array) && params[:user_id].present?
          user_ids = params[:user_id].to_a.map { |e| e.to_i  }

          # ensure that candidate group admin has been already in group
          user_ids_not_in_group = user_ids - user_ids_already_in_group
          if !user_ids_not_in_group.empty?
            raise InputError.new("Users with user_id #{user_ids_not_in_group} are not group participants.")
          end

          new_admin_ids = User.where("id IN (?)", user_ids).pluck(:id)

          new_admin_ids.each do |aid|
            c = ChatUser.find_by(chat_room_id: chat_room.id, user_id: aid)
            c.update_attribute(:is_group_admin, true)
          end

          # get user qiscus_email
          user_qiscus_emails = User.where("id IN (?)", user_ids).pluck(:qiscus_email)
        end

        # add group admins using array of qiscus email
        if params[:qiscus_email].kind_of?(Array) && params[:qiscus_email].present?
          user_qiscus_emails = params[:qiscus_email].to_a.map { |e| e.to_s  }
          registered_user_qiscus_emails = chat_room.users.pluck(:qiscus_email).to_a

          # ensure that candidate group admin has been already in group
          user_qiscus_email_not_in_group = user_qiscus_emails - registered_user_qiscus_emails
          if !user_qiscus_email_not_in_group.empty?
            raise InputError.new("Users with qiscus_email #{user_qiscus_email_not_in_group} are not group participants.")
          end

          new_admin_ids = User.where("qiscus_email IN (?)", user_qiscus_emails).pluck(:id)

          new_admin_ids.each do |aid|
            c = ChatUser.find_by(chat_room_id: chat_room.id, user_id: aid)
            c.update_attribute(:is_group_admin, true)
          end
        end

        # Backend need to post system event message after add participants as admin
        if !user_qiscus_emails.empty? || !user_qiscus_email.nil?
          subject_email = User.find(@current_user.id)
          user_qiscus_emails = user_qiscus_emails.uniq

          qiscus_sdk = QiscusSdk.new(@current_user.application.app_id, @current_user.application.qiscus_sdk_secret)

          user_qiscus_emails.each do |email|
            object_user = User.find_by(qiscus_email: email)

            # Define system_event_type to be stored in payload
            system_event_type = "add_group_admin"
            message = "#{subject_email.fullname} added #{object_user.fullname} as admin"

            # Create payload
            payload = {
              "system_event_type":    system_event_type,
              "subject_email":        subject_email,
              "object_email":         email,
              "subject":              subject_email,
              "object":               object_user,
              "message":              message
            }

            system_event_type = "custom"
            qiscus_sdk.post_system_event_message(system_event_type, chat_room.qiscus_room_id, "", [], "", payload.to_json, message)
          end
        end

      end

      # Get user_id that assign as group admin
      group_admins = User.where("id IN (?)", new_admin_ids)

      render json: {
        data: group_admins
      } and return

    rescue ActiveRecord::RecordInvalid => e
      msg = ""
      e.record.errors.map do |k, v|
        key = k.to_s.humanize
        msg = msg + "#{key} #{v}, "
      end

      msg = msg.chomp(", ") + "."
      render json: {
        error: {
          message: msg
        }
      }, status: 422 and return

    rescue => e
      render json: {
        error: {
          message: e.message,
          class: e.class.name
        }
      }, status: 422
    end
  end

  # =begin
  # @apiVersion 1.0.0
  # @api {delete} /api/v1/chat/conversations/:qiscus_room_id/admins/ Delete Group Admins
  # @apiName DeleteGroupAdmins
  # @apiGroup Group Chat Admin
  #
  # @apiParam {Number} qiscus_room_id Qiscus room id
  # @apiParam {Array} [user_id[]] Array of integer of user id, e.g: `user_id[]=1&user_id[]=2`
  # @apiParam {Array} [qiscus_email[]] Array of registered qiscus email, e.g: `qiscus_email[]=userid_6_qismetest3.mailinator.com@qisme.com&qiscus_email[]=userid_5_qismetest2.mailinator.com@qisme.com`
  # @apiParam {String} access_token User access token
  # =end
  def delete_group_admins
    begin
      chat_room = @chat_room
      delete_admin_ids = Array.new
      ActiveRecord::Base.transaction do
        if !params[:user_id].present? && !params[:qiscus_email].present?
          raise InputError.new("Array of user id or qiscus email must be present.")
        end

        user_ids_already_in_group = chat_room.users.pluck(:id)
        if user_ids_already_in_group.to_a.include?(@current_user.id) == false
          raise InputError.new("You are not member of this group.")
        end

        # only admin can delete group admin
        is_group_admin = ChatUser.find_by(chat_room_id: chat_room.id, user_id: @current_user.id, is_group_admin: true)
        if is_group_admin.nil?
          raise InputError.new("You are not admin of this group. Only admin can delete group admin.")
        end

        # delete group admins using array of user_id
        if params[:user_id].kind_of?(Array) && params[:user_id].present?
          user_ids = params[:user_id].to_a.map { |e| e.to_i  }

          # admin can't remove themselves from admin
          if user_ids.include?(@current_user.id)
            raise InputError.new("You can't remove yourself from admin.")
          end

          # ensure that candidate group admin has been already in group
          user_ids_not_in_group = user_ids - user_ids_already_in_group
          if !user_ids_not_in_group.empty?
            raise InputError.new("Users with user_id #{user_ids_not_in_group} are not group participants.")
          end

          delete_admin_ids = User.where("id IN (?)", user_ids).pluck(:id)

          delete_admin_ids.each do |aid|
            c = ChatUser.find_by(chat_room_id: chat_room.id, user_id: aid)
            c.update_attribute(:is_group_admin, false)
          end

          # get user qiscus_email
          user_qiscus_emails = User.where("id IN (?)", user_ids).pluck(:qiscus_email)

        end

        # delete group admins using array of qiscus email
        if params[:qiscus_email].kind_of?(Array) && params[:qiscus_email].present?
          user_qiscus_emails = params[:qiscus_email].to_a.map { |e| e.to_s  }
          registered_user_qiscus_emails = chat_room.users.pluck(:qiscus_email).to_a

          # admin can't remove themselves from admin
          if user_qiscus_emails.include?(@current_user.qiscus_email)
            raise InputError.new("You can't remove yourself from admin.")
          end

          # ensure that candidate group admin has been already in group
          user_qiscus_email_not_in_group = user_qiscus_emails - registered_user_qiscus_emails
          if !user_qiscus_email_not_in_group.empty?
            raise InputError.new("Users with qiscus_email #{user_qiscus_email_not_in_group} are not group participants.")
          end

          delete_admin_ids = User.where("qiscus_email IN (?)", user_qiscus_emails).pluck(:id)

          delete_admin_ids.each do |aid|
            c = ChatUser.find_by(chat_room_id: chat_room.id, user_id: aid)
            c.update_attribute(:is_group_admin, false)
          end
        end

        # Backend need to post system event message after remove participants as admin
        if !user_qiscus_emails.empty? || !user_qiscus_email.nil?
          subject_email = User.find(@current_user.id)
          user_qiscus_emails = user_qiscus_emails.uniq

          qiscus_sdk = QiscusSdk.new(@current_user.application.app_id, @current_user.application.qiscus_sdk_secret)

          user_qiscus_emails.each do |email|
            object_user = User.find_by(qiscus_email: email)

            # Define system_event_type to be stored in payload
            system_event_type = "remove_group_admin"
            message = "#{subject_email.fullname} removed #{object_user.fullname} as admin"

            # Create payload
            payload = {
              "system_event_type":    system_event_type,
              "subject_email":        subject_email,
              "object_email":         email,
              "subject":              subject_email,
              "object":               object_user,
              "message":              message,
            }

            system_event_type = "custom"
            qiscus_sdk.post_system_event_message(system_event_type, chat_room.qiscus_room_id, "", [], "", payload.to_json, message)
          end
        end

        # Get user_id that delete as group admin
        group_admins = User.where("id IN (?)", delete_admin_ids)

        render json: {
          data: group_admins
        } and return
      end

      render json: {
        data: nil
      } and return

    rescue ActiveRecord::RecordInvalid => e
      msg = ""
      e.record.errors.map do |k, v|
        key = k.to_s.humanize
        msg = msg + "#{key} #{v}, "
      end

      msg = msg.chomp(", ") + "."
      render json: {
        error: {
          message: msg
        }
      }, status: 422 and return

    rescue => e
      render json: {
        error: {
          message: e.message,
          class: e.class.name
        }
      }, status: 422
    end
  end

  private
    def ensure_eligible_access_to_chatroom
      if params[:chatroom_id].present? && params[:chatroom_id] != ""
        # only chat room maker who can add or remove participant for this group
        # @chat_room = ChatRoom.find_by(id: params[:chatroom_id], user_id: @current_user.id)
        @chat_room = ChatRoom.find_by(qiscus_room_id: params[:chatroom_id], application_id: @current_user.application.id)
        if @chat_room.nil?
          render json: {
            error: {
              message: 'You have no access to this chatroom or this chat room is not found.'
            }
          }, status: 401 and return
        else
          if !@chat_room.is_group_chat
            render json: {
            error: {
              message: "This is not group chat. You can't add/remove participants.",
              class: InputError.name
            }
        }, status: 422 and return
          end
        end
      else
        render json: {
          error: {
            message: 'Parameter chatroom_id required'
          }
        }, status: 400 and return
      end
    end


end
