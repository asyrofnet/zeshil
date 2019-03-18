class Api::V1::Admin::StatisticsController < ProtectedController
  before_action :authorize_admin

  # =begin
  # @apiVersion 1.0.0
  # @api {get} /api/v1/admin/statistics Application statistics
  # @apiName AdminApplicationStatisctic
  # @apiGroup Admin - Statistics
  # @apiPermission Admin
  # @apiDescription It will return user total, registered user per month, chat total, chat per month,
  # chat per type (single or group)
  #
  # @apiParam {String} access_token Admin access token
  # @apiSuccessExample {json} Success-Response:
  # { "data": { "user": { "total": 61, "user_register": [ { "month": "Mar 2017", "total_user": 44 }, { "month": "Apr 2017", "total_user": 17 } ] }, "chat": { "all_total": 89, "single_chat_total": 34, "group_chat_total": 55, "average_group_participant": 1, "all": [ { "month": "Mar 2017", "total_user": 37 }, { "month": "Apr 2017", "total_user": 52 } ], "group": [ { "month": "Mar 2017", "total": 31 }, { "month": "Apr 2017", "total": 24 } ], "single": [ { "month": "Apr 2017", "total": 28 }, { "month": "Mar 2017", "total": 6 } ] } } }
  # =end
  def index
    begin
      users = User.where(application_id: @current_user.application_id)
      per_month = users.group("DATE_TRUNC('month', users.created_at)").count

      # user per month register
      user_per_month = Array.new
      per_month.each do |k, v|
        tmp = Hash.new
        tmp["month"] = k.strftime('%b %Y')
        tmp["total_user"] = v

        user_per_month.push(tmp)
      end


      # chat room
      chat_room = ChatRoom.where('user_id IN (?)', users.pluck(:id))
      chat_per = chat_room.group("DATE_TRUNC('month', chat_rooms.created_at)").count

      chat_per_month = Array.new
      chat_per.each do |k, v|
        tmp = Hash.new
        tmp["month"] = k.strftime('%b %Y')
        tmp["total_user"] = v

        chat_per_month.push(tmp)
      end

      chat_group_per = chat_room.group("DATE_TRUNC('month', chat_rooms.created_at)").where(is_group_chat: true).count

      group_chat_per_month = Array.new
      chat_group_per.each do |k, v|
        tmp = Hash.new
        tmp["month"] = k.strftime('%b %Y')
        tmp["total"] = v

        group_chat_per_month.push(tmp)
      end

      chat_single_per = chat_room.group("DATE_TRUNC('month', chat_rooms.created_at)").where(is_group_chat: false).count

      single_chat_per_month = Array.new
      chat_single_per.each do |k, v|
        tmp = Hash.new
        tmp["month"] = k.strftime('%b %Y')
        tmp["total"] = v

        single_chat_per_month.push(tmp)
      end

      # average participant in each group chat
      group_ids = chat_room.where(is_group_chat: true).pluck(:id)
      each_group_participant = ChatUser.where('chat_room_id IN (?)', group_ids)
        .group('chat_room_id')
        .count()

      total_group_participant = 0
      each_group_participant.each do |k, v|
        total_group_participant += v
      end

      # avg = sum of data / row count
      avg_participant = total_group_participant / ChatUser.where('chat_room_id IN (?)', group_ids).count()

      render json: {
        data: {
          user: {
            total: users.count,
            user_register: user_per_month
          },

          chat: {
            all_total: chat_room.count,
            single_chat_total: chat_room.where(is_group_chat: false).count,
            group_chat_total: chat_room.where(is_group_chat: true).count,
            average_group_participant: avg_participant,

            all: chat_per_month,
            group: group_chat_per_month,
            single: single_chat_per_month
          }
          
        }
      }
    rescue Exception => e
      render json: {
        error: {
          message: e.message
        }
      }, status: 422
    end
  end

end