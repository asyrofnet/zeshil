class Api::V1::Contacts::OfficialsController < ProtectedController
  before_action :authorize_user

  # =begin
  # @apiVersion 1.0.0
  # @api {get} /api/v1/contacts/officials List of Official Account
  # @apiDescription show all official account
  # @apiName ListOfficialAccount
  # @apiGroup Contact
  #
  # @apiParam {String} access_token User access token
  # =end
  def index
    begin
      official_contacts = nil
      ActiveRecord::Base.transaction do
        role_official = Role.official
        user_ids = UserRole.where(role_id: role_official.id).pluck(:user_id)
        official_contacts = User.where("id IN (?)", user_ids).order(fullname: :asc)
        official_contacts = official_contacts.where(application_id: @current_user.application.id)

        official_contacts = official_contacts.as_json({:show_profile => false})

        favored_status = @current_user.contacts.pluck(:contact_id, :is_favored)
        official_contacts = official_contacts.map do |e|
          e.merge!('is_favored' => favored_status.to_h[ e["id"] ] )
        end

      end

      render json: {
        data: official_contacts
      }
    rescue Exception => e
      render json: {
        error: {
          message: e.message
        }
      }, status: 422 and return
    end
  end
end
