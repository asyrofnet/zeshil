class Api::V1::Chat::Conversations::ParticipantsController < ProtectedController
  before_action :authorize_user
  # expect index method, because it get participants for single and group chat room
  before_action :ensure_eligible_access_to_chatroom, except: [:index]

  PREFIX_KEY = "chat_room_user_"

  # =begin
  # @apiVersion 1.0.0
  # @api {get} /api/v1/chat/conversations/:qiscus_room_id/participants Get Group Participants
  # @apiName GroupParticipants
  # @apiGroup Group Chat Participant
  #
  # @apiParam {Number} qiscus_room_id Qiscus room id
  # @apiParam {String} access_token User access token
  # =end
  def index
    begin
      # participants = @chat_room
      chat_room = ChatRoom.find_by(qiscus_room_id: params[:chatroom_id], application_id: @current_user.application.id)
      participants = chat_room

      chat_room_id = participants.id

      group_participants =  participants.users.includes(:roles, :application).map(&:as_json)
      # Map is_group_admin key
      group_participants.map do |participant|
        is_group_admin = ChatUser.where(chat_room_id: chat_room_id, user_id: participant["id"]).pluck(:is_group_admin).first
        participant.merge!('is_group_admin' => is_group_admin)
      end

      # Get user_id that assign as group admin
      group_admin_ids = ChatUser.where(chat_room_id: chat_room_id).where(is_group_admin: true).pluck(:user_id)
      group_admins = User.where("id IN (?)", group_admin_ids).pluck(:id)

      render json: {
        # data: participants.users.includes(:roles, :application).map(&:as_json),
        data: group_participants,
        group_admins: group_admins
      }
    rescue Exception => e
      render json: {
        error: {
          message: e.message
        }
      }, status: 422
    end
  end

  # =begin
  # @apiVersion 1.0.0
  # @api {post} /api/v1/chat/conversations/:qiscus_room_id/participants Add Group Participants
  # @apiName GroupAddParticipants
  # @apiGroup Group Chat Participant
  #
  # @apiParam {Number} qiscus_room_id Qiscus room id
  # @apiParam {Array} [user_id[]] Array of integer of user id, e.g: `user_id[]=1&user_id[]=2`
  # @apiParam {Array} [qiscus_email[]] Array of registered qiscus email, e.g: `qiscus_email[]=userid_6_qismetest3.mailinator.com@qisme.com&qiscus_email[]=userid_5_qismetest2.mailinator.com@qisme.com`
  # @apiParam {String} access_token User access token
  # @apiParam {String} message Message to be posted they (participant[s]) is added
  # =end
  def create
    begin
      # data for post comment after data saved in qisme
      new_participants_for_post_comment = Array.new
      new_chat_users = Array.new
      chat_room = @chat_room
      new_participant_ids = Array.new
      new_participant_emails = Array.new

      ActiveRecord::Base.transaction do
        # if group_chat is not channel, set maximum member to 100
        if !chat_room.is_channel
          total_participants = chat_room.users.count
          if total_participants > 100
            raise Exception.new("You cannot add more than 100 participants in group chat. Please use channel instead")
          end
        end

        user_ids_already_in_group = chat_room.users.pluck(:id).to_a
        if user_ids_already_in_group.include?(@current_user.id) == false
          raise Exception.new("You are not member of this group.")
        end

        # only admin can add group participants
        is_group_admin = ChatUser.find_by(chat_room_id: chat_room.id, user_id: @current_user.id, is_group_admin: true)
        if is_group_admin.nil?
          raise Exception.new("You are not admin of this group. Only admin can add group participants.")
        end

        if !params[:user_id].present? && !params[:qiscus_email].present?
          raise Exception.new("Array of user id or qiscus email must be present.")
        end

        if params[:user_id].kind_of?(Array) && params[:user_id].present?

          user_ids = params[:user_id].to_a.map { |e| e.to_i  }
          # only get user id where aren't ready in group
          user_ids = user_ids - user_ids_already_in_group

          new_participants = User.includes(:roles, :application).where("users.id IN (?)", user_ids)
          new_participant_emails = new_participants.pluck(:qiscus_email)
          new_participant_ids = new_participants.pluck(:id)

          # add to new participant array
          new_participants_for_post_comment = new_participants_for_post_comment + new_participants

          new_participant_ids.each do |uid|
            tmp = Hash.new
            tmp[:chat_room_id] = chat_room.id
            tmp[:user_id] = uid
            new_chat_users.push(tmp)
          end

          # add to sdk participant
          if !new_participant_emails.empty?
            qiscus_sdk = QiscusSdk.new(@current_user.application.app_id, @current_user.application.qiscus_sdk_secret)
            qiscus_sdk.add_room_participants(new_participant_emails, chat_room.qiscus_room_id.to_i)
          end
        end

        # Add participant using array of qiscus email
        if params[:qiscus_email].kind_of?(Array) && params[:qiscus_email].present?

          user_qiscus_emails = params[:qiscus_email].to_a.map { |e| e.to_s  }
          registered_user_qiscus_emails = chat_room.users.pluck(:qiscus_email).to_a
          # only get user with qiscus email where aren't ready in group
          user_qiscus_emails = user_qiscus_emails - registered_user_qiscus_emails

          new_participants = User.includes(:roles, :application).where("users.qiscus_email IN (?)", user_qiscus_emails)
          new_participant_emails = new_participants.pluck(:qiscus_email)
          new_participant_ids = new_participants.pluck(:id)

          # add to new participant array
          new_participants_for_post_comment = new_participants_for_post_comment + new_participants

          new_participant_ids.each do |uid|
            tmp = Hash.new
            tmp[:chat_room_id] = chat_room.id
            tmp[:user_id] = uid
            new_chat_users.push(tmp)
          end

          # add to sdk participant
          if !new_participant_emails.empty?
            qiscus_sdk = QiscusSdk.new(@current_user.application.app_id, @current_user.application.qiscus_sdk_secret)
            qiscus_sdk.add_room_participants(new_participant_emails, chat_room.qiscus_room_id.to_i)
          end
        end

        # get only uniq user to prevent duplicate data
        new_chat_users = new_chat_users.uniq
        ChatUser.create(new_chat_users)

      end

      # post message to group chat to make user notice about user add
      # post here to make sure all user has been added and commited to transaction before send to hooks
      if !params[:message].nil? && params[:message] != ""
        qiscus_sdk = QiscusSdk.new(@current_user.application.app_id, @current_user.application.qiscus_sdk_secret)
        new_participants_for_post_comment.each do | new_participant |
          qiscus_sdk.post_comment(new_participant.qiscus_token, @chat_room.qiscus_room_id.to_i, params[:message])
        end
      end

      # Backend need to post system event message after add group participants
      if !new_participant_emails.empty?
        system_event_type = "add_member"
        qiscus_sdk = QiscusSdk.new(@current_user.application.app_id, @current_user.application.qiscus_sdk_secret)
        qiscus_sdk.post_system_event_message(system_event_type, @chat_room.qiscus_room_id.to_i, @current_user.qiscus_email, new_participant_emails, "")

      end

      chat_room = ChatRoom.includes(
        [
          :user => [],
          :chat_users => [],
          :users => [:roles, :application],
          :target => [:roles, :application]
        ]).find(chat_room.id).as_json()

      render json: {
        data: chat_room
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

    rescue Exception => e
      render json: {
        error: {
          message: e.message
        }
      }, status: 422
    end
  end

  # =begin
  # @apiVersion 1.0.0
  # @api {delete} /api/v1/chat/conversations/:qiscus_room_id/participants Delete Group Participants
  # @apiDescription use this alias `POST /api/v1/chat/conversations/:qiscus_room_id/delete_participants` if you prefer POST method,
  # since in Delete method will cause error when it requested by unstable connection in client side.
  #
  # @apiName DeleteAddParticipants
  # @apiGroup Group Chat Participant
  #
  # @apiParam {Number} qiscus_room_id Qiscus room id
  # @apiParam {Array} [user_id[]] Array of integer of user id, e.g: `user_id[]=1&user_id[]=2`
  # @apiParam {Array} [qiscus_email[]] Array of registered qiscus email, e.g: `qiscus_email[]=userid_6_qismetest3.mailinator.com@qisme.com&qiscus_email[]=userid_5_qismetest2.mailinator.com@qisme.com`
  # @apiParam {String} access_token User access token
  # @apiParam {String} message Message to be posted they (participant[s]) is removed
  # =end
  def delete_participants
    begin
      ActiveRecord::Base.transaction do
        chat_room = @chat_room

        if !params[:user_id].present? && !params[:qiscus_email].present?
          raise Exception.new("Array of user id or qiscus email must be present.")
        end

        # only admin can delete group participants
        is_group_admin = ChatUser.find_by(chat_room_id: chat_room.id, user_id: @current_user.id, is_group_admin: true)
        if is_group_admin.nil?
          raise Exception.new("You are not admin of this group. Only admin can delete group participants.")
        end

        user_ids_already_in_group = chat_room.users.pluck(:id)
        if user_ids_already_in_group.to_a.include?(@current_user.id) == false
          raise Exception.new("You are not member of this group.")
        end

        if params[:user_id].kind_of?(Array) && params[:user_id].present?

          user_ids = params[:user_id].to_a.map { |e| e.to_i  }
          user_unpermitted_to_remove = user_ids_already_in_group - user_ids
          user_permitted_to_remove = user_ids_already_in_group - user_unpermitted_to_remove

          to_be_deleted = User.includes(:roles, :application).where("users.id IN (?)", user_permitted_to_remove)
          deleted_participant_emails = to_be_deleted.pluck(:qiscus_email)
          deleted_participant_ids = to_be_deleted.pluck(:id)

          chat_user = ChatUser.where("chat_users.user_id IN (?)", deleted_participant_ids)
          chat_user = chat_user.where(chat_room_id: chat_room.id)
          chat_user.destroy_all

          # Begin delete redis cache
          keys = []
          user_ids.each do |uid|
            k = "#{PREFIX_KEY}#{uid}"
            keys.push(k)
          end

          # Redis SET, GET and DEL is atomic.
          if !keys.empty?
            $redis.del(keys)
          end
          # End delete redis cache


          # delete from sdk participants
          if !deleted_participant_emails.empty?
            qiscus_sdk = QiscusSdk.new(@current_user.application.app_id, @current_user.application.qiscus_sdk_secret)

            # post comment when users are removed, post before remove
            if !params[:message].nil? && params[:message] != ""
              to_be_deleted.each do | to_delete |
                qiscus_sdk.post_comment(to_delete.qiscus_token, chat_room.qiscus_room_id.to_i, params[:message])
              end
            end

            # Post system event message before remove participants
            # It's to make sure that all participants get system event message
            system_event_type = "remove_member"
            qiscus_sdk.post_system_event_message(system_event_type, chat_room.qiscus_room_id.to_i, @current_user.qiscus_email, deleted_participant_emails, "")

            qiscus_sdk.remove_room_participants(deleted_participant_emails, chat_room.qiscus_room_id.to_i)
          end
        end

        if params[:qiscus_email].kind_of?(Array) && params[:qiscus_email].present?

          user_qiscus_emails = params[:qiscus_email].to_a.map { |e| e.to_s  }
          user_qiscus_emails_already_in_group = chat_room.users.pluck(:qiscus_email)

          user_unpermitted_to_remove = user_qiscus_emails_already_in_group - user_qiscus_emails
          user_permitted_to_remove = user_qiscus_emails_already_in_group - user_unpermitted_to_remove

          to_be_deleted = User.includes(:roles, :application).where("users.qiscus_email IN (?)", user_permitted_to_remove)
          deleted_participant_emails = to_be_deleted.pluck(:qiscus_email)
          deleted_participant_ids = to_be_deleted.pluck(:id)

          chat_user = ChatUser.where("chat_users.user_id IN (?)", deleted_participant_ids)
          chat_user = chat_user.where(chat_room_id: chat_room.id)
          chat_user.destroy_all

          # delete from sdk participants
          if !deleted_participant_emails.empty?
            qiscus_sdk = QiscusSdk.new(@current_user.application.app_id, @current_user.application.qiscus_sdk_secret)

            # post comment when users are removed, post before remove
            if !params[:message].nil? && params[:message] != ""
              to_be_deleted.each do | to_delete |
                qiscus_sdk.post_comment(to_delete.qiscus_token, chat_room.qiscus_room_id.to_i, params[:message])
              end
            end

            # Post system event message before remove participants
            # It's to make sure that all participants get system event message
            system_event_type = "remove_member"
            qiscus_sdk.post_system_event_message(system_event_type, chat_room.qiscus_room_id.to_i, @current_user.qiscus_email, deleted_participant_emails, "")

            qiscus_sdk.remove_room_participants(deleted_participant_emails, chat_room.qiscus_room_id.to_i)
          end
        end

        chat_room = ChatRoom.includes(
        [
          :user => [],
          :chat_users => [],
          :users => [:roles, :application],
          :target => [:roles, :application]
        ]).find(chat_room.id).as_json()

        render json: {
          data: chat_room
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

    rescue Exception => e
      render json: {
        error: {
          message: e.message
        }
      }, status: 422
    end
  end

  # =begin
  # @apiVersion 1.0.0
  # @api {post} /api/v1/chat/conversations/:qiscus_room_id/leave_group Leave Group
  # @apiName LeaveGroup
  # @apiGroup Group Chat Participant
  #
  # @apiParam {Number} qiscus_room_id Qiscus room id
  # @apiParam {String} access_token User access token
  # =end
  def leave_group
    begin
      chat_room = @chat_room
      ActiveRecord::Base.transaction do
        if !params[:qiscus_room_id].present?
          raise Exception.new("Qiscus room id must be present.")
        end

				application = @current_user.application

        user_ids_already_in_group = chat_room.users.pluck(:id)
        if user_ids_already_in_group.to_a.include?(@current_user.id) == false
          raise Exception.new("You are not member of this group.")
        end

        is_group_admin = ChatUser.find_by(chat_room_id: chat_room.id, user_id: @current_user.id, is_group_admin: true)
        participants_count = ChatUser.where(chat_room_id: chat_room.id).count
        count_group_admin = ChatUser.where(chat_room_id: chat_room.id, is_group_admin: true).count

        if is_group_admin && count_group_admin == 1 && participants_count > 1
          first_participant = chat_room.chat_users.where(is_group_admin: false).first
          first_participant.is_group_admin = true
          first_participant.save
        end

        # delete from chat_user table
        chat_user = ChatUser.find_by(user_id: @current_user.id, chat_room_id: chat_room.id)
        if chat_user.nil? == false
          chat_user.destroy
        end

        qiscus_sdk = QiscusSdk.new(@current_user.application.app_id, @current_user.application.qiscus_sdk_secret)


        # backend need to post system event message before user leave group
        # post system event message only for group chat that is not public chat
        if chat_room.is_public_chat == false
          system_event_type = "left_room"
          qiscus_sdk.post_system_event_message(system_event_type, chat_room.qiscus_room_id.to_i, @current_user.qiscus_email, [], "")
        end

        # delete from sdk participants
        qiscus_sdk.remove_room_participants([@current_user.qiscus_email], chat_room.qiscus_room_id.to_i)

        # Begin delete redis cache
        user_ids = [@current_user.id]
        keys = []
        user_ids.each do |uid|
          k = "#{PREFIX_KEY}#{uid}"
          keys.push(k)
        end

        # Redis SET, GET and DEL is atomic.
        if !keys.empty?
          $redis.del(keys)
        end
        # End delete redis cache

        chat_room = ChatRoom.includes(
        [
          :user => [],
          :chat_users => [],
          :users => [:roles, :application],
          :target => [:roles, :application]
        ]).find(chat_room.id).as_json()

        render json: {
          data: chat_room
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

    rescue Exception => e
      render json: {
        error: {
          message: e.message
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
            raise Exception.new("This is not group chat. You can't add/remove participants.")
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
