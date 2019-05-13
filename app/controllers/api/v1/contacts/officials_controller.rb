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

      # NEXTnya perlu pagination

      official_contacts = nil
      bot_contacts = nil
      ActiveRecord::Base.transaction do
        # get official account users
        role_official = Role.official
        user_ids = UserRole.where(role_id: role_official.id).pluck(:user_id)
        official_contacts = User.where("id IN (?)", user_ids)
          .where(application_id: @current_user.application_id)
          .order(fullname: :asc)
          .as_json({:show_profile => false})

        favored_status = @current_user.contacts.pluck(:contact_id, :is_favored)
        official_contacts = official_contacts.map do |e|
          e.merge!('is_favored' => favored_status.to_h[ e["id"] ] )
        end
      end

      ActiveRecord::Base.transaction do
        # except official, member
        sql = <<-SQL
          contacts.contact_id NOT IN (
            SELECT user_id 
            FROM user_roles 
            WHERE role_id = ? OR role_id = ?
          )
        SQL
        
        contact_id = @current_user.contacts
          .where(sql, Role.official.id, Role.member.id)
          .pluck(:contact_id)

        bot_contacts = User.includes([:roles, :application])
          .where("users.application_id = ?", @current_user.application_id)
          .where("users.id IN (?)", contact_id)
          .where.not(fullname: nil)
          .where.not(fullname: "") # only show contact who has complete their profile (fullname not nil)
          .order(fullname: :asc)
          .as_json({:show_profile => false})
        
        favored_status = @current_user.contacts.pluck(:contact_id, :is_favored)
        bot_contacts = bot_contacts.map do |e|
          e.merge!('is_favored' => favored_status.to_h[ e["id"] ] )
        end
      end

      render json: {
        data: official_contacts + bot_contacts
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
