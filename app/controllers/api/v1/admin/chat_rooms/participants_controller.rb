class Api::V1::Admin::ChatRooms::ParticipantsController < ProtectedController
  before_action :authorize_admin

  def index
    begin
      participants = ChatRoom.find(params[:chatroom_id])
      render json: {
        data: participants.users.map(&:as_json)
      }
    rescue Exception => e
      render json: {
        error: {
          message: e.message
        }
      }, status: 422
    end
  end


  # Add participant to chat room
  # need to add to qiscus sdk
  def create
    begin
      ActiveRecord::Base.transaction do
        chat_room = ChatRoom.find(params[:chatroom_id])

        if !chat_room.is_group_chat
          raise Exception.new("This is not group chat. You can't add another participants.")
        end

        if params[:user_id].kind_of?(Array) && params[:user_id].present?

          params[:user_id].each do |uid|
            if ChatUser.find_by(user_id: uid, chat_room_id: chat_room.id).nil?
              chat_user = ChatUser.new
              chat_user.user_id = uid
              chat_user.chat_room_id = chat_room.id
              chat_user.save!
            end
          end

        end

        render json: {
          data: chat_room.as_json()
        } and return
      end

      render json: {
        data: nil
      } and return

    rescue Exception => e
      render json: {
        error: {
          message: e.message
        }
      }, status: 422
    end
  end

  # need to delete on qiscus sdk too
  def delete_participants
    begin
      ActiveRecord::Base.transaction do
        chat_room = ChatRoom.find(params[:chatroom_id])

        if !chat_room.is_group_chat
          raise Exception.new("This is not group chat. You can't remove participants.")
        end

        if params[:user_id].kind_of?(Array) && params[:user_id].present?

          params[:user_id].each do |uid|
            chat_user = ChatUser.find_by(user_id: uid, chat_room_id: chat_room.id)
            if !chat_user.nil?
              chat_user.destroy
            end
          end

        end

        render json: {
          data: chat_room.as_json()
        } and return
      end

      render json: {
        data: nil
      } and return

    rescue Exception => e
      render json: {
        error: {
          message: e.message
        }
      }, status: 422
    end
  end


end