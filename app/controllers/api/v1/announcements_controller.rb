class Api::V1::AnnouncementsController < ProtectedController
  before_action :authorize_user

  # =begin
  # @apiVersion 1.0.0
  # @api {get} /api/v1/announcements Announcement List
  # @apiName AnnouncementList
  # @apiGroup Announcement
  #
  # @apiParam {String} access_token User access token
  # @apiParam {Number} [page=1] Page number 
  # =end
  def index
    announcements = Announcement.where(application_id: @current_user.application_id).page(params[:page])

    render json: {
      status: 'success',
      data: {
        announcement: announcements
      }
    }, status: 200 
  end

  # =begin
  # @apiVersion 1.0.0
  # @api {get} /api/v1/announcements/last Get Newst Announcements
  # @apiName GetNewestAnnouncement
  # @apiGroup Announcement
  #
  # @apiParam {String} access_token User access token
  # =end
  def last
    announcements = Announcement.where(is_active: true, application_id: @current_user.application_id).last

    render json: {
      status: 'success',
      data: {
        announcement: announcements
      }
    }, status: 200
  end


end
