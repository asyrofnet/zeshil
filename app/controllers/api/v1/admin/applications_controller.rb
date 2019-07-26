require 'securerandom'

class Api::V1::Admin::ApplicationsController < ProtectedController
  before_action :authorize_admin

  # =begin
  # @apiVersion 1.0.0
  # @api {get} /api/v1/admin/applications Index All Registered Application
  # @apiName AllApplication
  # @apiGroup Admin - Application
  # @apiPermission Admin
  #
  # @apiParam {String} access_token Admin access token
  # @apiParam {String} app_id Filter by application id scope name with no space, i.e: `qisme`, `kiwari-prod`
  # @apiParam {String} app_name Filter by application name
  # @apiParam {Number} [page=1] Page number
  # =end
  def index
    applications = Application.all
    applications = applications.where("LOWER(app_id) LIKE ?", "%#{params[:app_id]}%") if !params[:app_id].nil? && params[:app_id] != ""
    applications = applications.where("LOWER(app_name) LIKE ?", "%#{params[:app_name]}%") if !params[:app_name].nil? && params[:app_name] != ""

    total = applications.count
    applications = applications.page(params[:page]).per(25)

    render json: {
      per_page: 25,
      total_data: total,
      data: applications
    }
  end

  # =begin
  # @apiVersion 1.0.0
  # @api {get} /api/v1/admin/applications/:id Show detail of an application
  # @apiName ShowApplication
  # @apiGroup Admin - Application
  # @apiPermission Admin
  #
  # @apiParam {String} access_token Admin access token
  # @apiParam {Number} id Application id
  # =end
  def show
    application = Application.find(params[:id])

    render json: {
      data: application
    }
  end

  # =begin
  # @apiVersion 1.0.0
  # @api {post} /api/v1/admin/applications Add New Application
  # @apiName AddApplication
  # @apiGroup Admin - Application
  # @apiPermission Admin
  #
  # @apiParam {String} access_token Admin access token
  # @apiParam {String} app_id Application id, like `qisme` or `kiwari-prod`.
  # Please don't input any string with spaces, it just alphanumeric only
  #
  # @apiParam {String} app_name Application name
  # @apiParam {String} description Application description
  # @apiParam {String} qiscus_sdk_secret Qiscus SDK secret
  # @apiParam {String} phone_number Phone number for default admin of this application
  # @apiParam {String} [fullname=Admin] Default admin's fullname of this application
  # @apiParam {String} gender Default admin's gender, `male` or `female` only.
  # =end
  def create
    begin
      if params[:app_id] == "" || params[:app_name] == "" || params[:qiscus_sdk_secret] == ""
        raise StandardError.new("app_id and app_name can't be empty.")
      end

      application = nil
      ActiveRecord::Base.transaction do
        application = Application.new
        application.app_id = params[:app_id]
        application.qiscus_sdk_secret = params[:qiscus_sdk_secret]
        application.app_name = params[:app_name]
        application.description = params[:description]
        application.qiscus_sdk_url = "http://" + params[:app_id].to_s + ".qiscus.com"
        application.save!

        admin_role = Role.admin
        member_role = Role.member

        if admin_role.nil? || member_role.nil?
          render json: {
            error: {
              message: "Role admin and member not found."
            }
          }, status: 422
        end

        email_sdk = params[:phone_number].tr('+', '').delete(' ')
        email_sdk = email_sdk + "@" + application.app_id + ".com" # will build string like 085868xxxxxx@app_id.com

        password = SecureRandom.hex # generate random password for security reason

        # set default user avatar_url
        avatar_url = "https://d1edrlpyc25xu0.cloudfront.net/image/upload/t5XWp2PBRt/1510641299-default_user_avatar.png"

        # Backend no need to register user in SDK
        qiscus_sdk = QiscusSdk.new(application.app_id, application.qiscus_sdk_secret)
        qiscus_token = qiscus_sdk.login_or_register_rest(email_sdk, password, email_sdk, avatar_url) # get qiscus token

        user = User.new(
          phone_number: params[:phone_number],
          email: email_sdk,
          fullname: params[:fullname] || "Admin",
          gender: params[:gender],
          date_of_birth: Time.now,
          application_id: application.id,
          qiscus_email: email_sdk,
          qiscus_token: qiscus_token
        )

        user.save!

        user_role = UserRole.new
        user_role.user_id = user.id
        user_role.role_id = admin_role.id
        user_role.save!

        user_role = UserRole.new
        user_role.user_id = user.id
        user_role.role_id = member_role.id
        user_role.save!

      end

      render json: {
        data: application
      }
    rescue => e
      render json: {
        error: {
          message: e.message
        }
      }, status: 422
    end
  end

  # =begin
  # @apiVersion 1.0.0
  # @api {patch} /api/v1/admin/applications/:id Update Application
  # @apiName UpdateApplication
  # @apiGroup Admin - Application
  # @apiPermission Admin
  #
  # @apiParam {Number} id Application id to update
  # @apiParam {String} access_token Admin access token
  #
  # @apiParam {String} app_name Application name
  # @apiParam {String} description Application description
  # @apiParam {String} qiscus_sdk_secret Qiscus SDK secret
  # =end
  def update
    begin
      application = nil
      ActiveRecord::Base.transaction do
        application = Application.find(params[:id])
        # admin can't edit app_id once it created, admin must create new app.
        # application.app_id = params[:app_id] if !params[:app_id].nil? && params[:app_id] != ""
        application.app_name = params[:app_name] if !params[:app_name].nil? && params[:app_name] != ""
        application.qiscus_sdk_secret = params[:qiscus_sdk_secret] if !params[:qiscus_sdk_secret].nil? && params[:qiscus_sdk_secret] != ""
        application.description = params[:description] if !params[:description].nil? && params[:description] != ""
        # application.qiscus_sdk_url = "http://" + params[:app_id].to_s + ".qiscus.com" if !params[:app_id].nil? && params[:app_id] != ""
        application.save!
      end

      render json: {
        data: application
      }
    rescue => e
      render json: {
        error: {
          message: e.message
        }
      }, status: 422
    end
  end

  # =begin
  # @apiVersion 1.0.0
  # @api {delete} /api/v1/admin/applications/:id Delete Application
  # @apiName DeleteApplication
  # @apiPermission Admin
  # @apiDescription For security reason, admin can only destroy their own application.
  # Admin can't delete other application even if he was created that application.
  #
  # @apiGroup Admin - Application
  #
  # @apiParam {Number} id Application id to update
  # @apiParam {String} access_token Admin access token
  #
  # =end
  def destroy
    application = nil
    ActiveRecord::Base.transaction do
      application = Application.find(params[:id])

      if @current_user.application.id != application.id
        render json: {
          error: {
            message: "For security reason, admin can only destroy their own application. Admin can't delete other application even if he was created that application."
          }
        }, status: 400 and return
      end

      if application.nil? == false
        application.destroy
      end
    end

    render json: {
      data: application
    }
  end

  # =begin
  # @apiVersion 1.0.0
  # @api {get} /api/v1/admin/applications/:id/users Get users of an application
  # @apiName ApplicationUsers
  # @apiPermission Admin
  #
  # @apiGroup Admin - Application
  #
  # @apiParam {Number} id Application id to update
  # @apiParam {String} access_token Admin access token
  # @apiParam {String} fullname Filter by fullname
  # @apiParam {String} email Filter by email
  # @apiParam {String} phone_number Filter by phone_number
  # @apiParam {Number} [page=1] Page number
  #
  # =end
  def users
    application = Application.find(params[:id])

    if application.nil?
      raise StandardError.new("Application not found.")
    end

    users = application.users
    users = users.where("LOWER(fullname) LIKE ?", "%#{params[:fullname]}%") if !params[:fullname].nil? && params[:fullname] != ""
    users = users.where("LOWER(email) LIKE ?", "%#{params[:email]}%") if !params[:email].nil? && params[:email] != ""
    users = users.where("LOWER(phone_number) LIKE ?", "%#{params[:phone_number]}%") if !params[:phone_number].nil? && params[:phone_number] != ""

    total = users.count
    per_page = 25
    users = users.page(params[:page]).per(per_page)

    # roundup total_page
    total_page = (total/per_page.to_f).ceil

    render json: {
      total: total,
      per_page: per_page,
      total_page: total_page,
      current_page: (params[:page].to_i <= 0) ? 1 : params[:page].to_i,
      data: users.as_json({:show_profile => true})
    }
  end

end