class Api::V1::Files::UploaderController < ProtectedController
  before_action :authorize_user
  before_action :ensure_raw_file, only: [:create]

  # =begin
  # @apiVersion 1.0.0
  # @api {post} /api/v1/files/uploader Upload File
  # @apiDescription This route is use by mobile client to upload file, and will return response from qiscus uploader (such as file url)
  # @apiName Uploader
  # @apiGroup Files
  #
  # @apiParam {String} access_token User access token
  # @apiParam {File} raw_file Raw file to be uploaded (commonly is an image)
  # =end
  def create
    begin
      qiscus_sdk = QiscusSdk.new(@current_user.application.app_id, @current_user.application.qiscus_sdk_secret)
      url = qiscus_sdk.upload_file(@current_user.qiscus_token, @raw_file)
      # folder = "files_#{@current_user.application.app_id}_user_id_#{@current_user.id}"
      # cloudinary = Cloudinary::Uploader.upload(@raw_file, resource_type: 'auto', folder: folder)
      render json: {
        data: {
          url: url
        }
        # data: cloudinary
      }

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
          message: e.message
        }
      }, status: 422 and return
    end
  end

  private
    def ensure_raw_file
      @raw_file = params[:raw_file]

      render json: {
        status: 'fail',
        message: 'invalid raw file'
      }, status: 422 unless @raw_file
    end
end