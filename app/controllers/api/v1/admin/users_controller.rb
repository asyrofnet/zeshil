require 'csv'
require 'securerandom'

class Api::V1::Admin::UsersController < ProtectedController
  before_action :authorize_admin
  before_action :ensure_create_params, only: [:create, :update]
  before_action :ensure_raw_file, only: [:import, :send_message]
  before_action :ensure_update_avatar_params, only: [:update_avatar]

  # =begin
  # @apiVersion 1.0.0
  # @api {get} /api/v1/admin/users List of User
  # @apiDescription You can use get `/api/v1/admin/users.csv` to export using same params.
  # @apiName AdminListofUser
  # @apiGroup Admin - User
  # @apiPermission Admin
  #
  # @apiParam {String} access_token Admin access token
  # @apiParam {String} email Filter by email
  # @apiParam {String} fullname Filter by fullname
  # @apiParam {String} phone_number Filter by phone_number
  # @apiParam {Number} [page=1] Pagination number
  # =end
  def index
    begin
      users = User.where(application_id: @current_user.application_id).where.not(id: @current_user.id).order(created_at: :desc)

      users = users.where("LOWER(email) LIKE ?", "%#{params[:email]}%") if !params[:email].nil? && params[:email] != ""
      users = users.where("LOWER(fullname) LIKE ?", "%#{params[:fullname]}%") if !params[:fullname].nil? && params[:fullname] != ""
      users = users.where("LOWER(phone_number) LIKE ?", "%#{params[:phone_number]}%") if !params[:phone_number].nil? && params[:phone_number] != ""


      respond_to do |format|
        format.csv {
          attributes = %w{id fullname phone_number email gender date_of_birth}
          csv_string = CSV.generate(headers: true) do |csv|
            csv << attributes
            users.each do |row|
              csv << attributes.map{ |attr| row[attr] }
            end
          end

          send_data(csv_string, filename: "users-data-#{Date.today}.csv")
        }

        format.json {
          total = users.count
          users = users.page(params[:page]).per(25)

          render json: {
            per_page: 25,
            total_data: total,
            data: users.as_json({:show_profile => true})
          }
        }
      end
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
  # @api {get} /api/v1/admin/users/:id Get User By Id
  # @apiName AdminGetUserById
  # @apiGroup Admin - User
  # @apiPermission Admin
  #
  # @apiParam {String} access_token Admin access token
  # @apiParam {Number} id User id
  # =end
  def show
    begin
      user = nil
      if params[:id] == @current_user.id.to_s
        raise Exception.new("You can not show your own profile. Please use /me instead.")
      end
      user = User.where(application_id: @current_user.application_id).where(id: params[:id]).first
      render json: {
        data: user.as_json({:show_profile => true})
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
  # @api {patch} /api/v1/admin/users/:id Update User By Id
  # @apiName AdminUpdateUserById
  # @apiGroup Admin - User
  # @apiPermission Admin
  #
  # @apiParam {String} access_token Admin access token
  # @apiParam {Number} user[id] User id
  # @apiParam {String} user[phone_number] Update phone number (must valid phone number)
  # @apiParam {String} user[fullname] Update name
  # @apiParam {String} user[email] Update email
  # @apiParam {String} user[gender] Update gender (male or female)
  # @apiParam {String} user[date_of_birth] Update date of birth (format: `YYYY-mm-dd`)
  # @apiParam {String} user[is_public] Profile status
  # @apiParam {String} user[description] User status or official account description
  # @apiParam {File} user[avatar_file] Update avatar
  # @apiParam {String} user[callback_url] Callback url for Bot account (official account)
  # @apiParam {Array} user[role_id][] Add roles. For example you cand send `user[role_id][]=1&user[role_id]=[]2` or `user[role_id]=1`
  # =end
  def update
    begin
      user = nil
      if params[:id] == @current_user.id.to_s
        raise Exception.new("You can not change your own profile. Please use /me instead.")
      end

      user_params = params[:user].permit!

      user = User.where(application_id: @current_user.application_id).where(id: params[:id]).first
      user.phone_number = user_params[:phone_number] if !user_params[:phone_number].nil? && user_params[:phone_number] != ""
      user.fullname = user_params[:fullname] if !user_params[:fullname].nil? && user_params[:fullname] != ""
      user.email = user_params[:email] if !user_params[:email].nil? && user_params[:email] != ""
      user.gender = user_params[:gender] if !user_params[:gender].nil? && user_params[:gender] != ""
      user.date_of_birth = user_params[:date_of_birth] if !user_params[:date_of_birth].nil? && user_params[:date_of_birth] != ""
      user.is_public = user_params[:is_public] if !user_params[:is_public].nil? && user_params[:is_public] != ""
      user.description = user_params[:description] if user_params[:description].present? && !user_params[:description].nil? && user_params[:description] != ""

      if !user_params[:avatar_file].nil? && user_params[:avatar_file] != ""
        qiscus_sdk = QiscusSdk.new(user.application.app_id, user.application.qiscus_sdk_secret)
        url = qiscus_sdk.upload_file(@current_user.qiscus_token, user_params[:avatar_file])

        user.avatar_url = url
      end

      if user_params[:callback_url].present? && !user_params[:callback_url].nil? && user_params[:callback_url] != ""
        user.callback_url = user_params[:callback_url]
      end

      user.save!

      # if role_id is exist as array
      if user_params[:role_id].kind_of?(Array) && user_params[:role_id].present?
        user.roles = Role.where("id IN (?)", user_params[:role_id].to_a)
        user.save!
      elsif user_params[:role_id].present? && !user_params[:role_id].nil? && user_params[:role_id] != ""
        user.roles = Role.where(id: user_params[:role_id].to_i)
        user.save!
      end

      render json: {
        data: user.as_json({:show_profile => true})
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
  # @api {post} /api/v1/admin/users Create User
  # @apiName AdminCreateUser
  # @apiGroup Admin - User
  # @apiPermission Admin
  #
  # @apiParam {String} access_token Admin access token
  # @apiParam {String} user[phone_number] User phone number (must valid phone number)
  # @apiParam {String} user[email] User email
  # @apiParam {String} user[fullname] User name
  # @apiParam {String} user[gender] User gender (male or female)
  # @apiParam {String} user[date_of_birth] User date of birth (format: `YYYY-mm-dd`)
  # @apiParam {String} user[is_public] Profile status (true or false)
  # @apiParam {String} user[description] User status or official account description
  # @apiParam {String} user[callback_url] Callback url for Bot account (official account)
  # @apiParam {Array} user[role_id][] Add roles. For example you cand send `user[role_id][]=1&user[role_id][]=2` or `user[role_id]=1`. By default member role will be assigned if you don't send anything.
  # =end
  def create
    begin
      user = nil
      ActiveRecord::Base.transaction do
        application_id = @current_user.application_id
        application = Application.find(application_id)

        user_params = params[:user].permit!

        email_sdk = user_params[:phone_number].tr('+', '').delete(' ')
        email_sdk = email_sdk + "@" + application.app_id + ".com" # will build string like 085868xxxxxx@app_id.com

        password = SecureRandom.hex # generate random password for security reason

        # set default user avatar
        avatar_url = "https://d1edrlpyc25xu0.cloudfront.net/image/upload/t5XWp2PBRt/1510641299-default_user_avatar.png"

        # try register to qiscus SDK
        qiscus_sdk = QiscusSdk.new(application.app_id, application.qiscus_sdk_secret)
        qiscus_token = qiscus_sdk.login_or_register_rest(email_sdk, password, email_sdk, avatar_url) # get qiscus token

        # then save!
        user = User.new
        user.phone_number = user_params[:phone_number]
        user.email = user_params[:email]
        user.fullname = user_params[:fullname]
        user.gender = user_params[:gender]
        user.date_of_birth = user_params[:date_of_birth]
        user.is_public = (user_params[:is_public].nil? || user_params[:is_public] == "" || user_params[:is_public] != "true") ? false : user_params[:is_public]
        user.qiscus_token = qiscus_token
        user.qiscus_email = email_sdk
        user.application_id = application_id
        user.description = user_params[:description] if user_params[:description].present? && !user_params[:description].nil? && user_params[:description] != ""

        if user_params[:callback_url].present? && !user_params[:callback_url].nil? && user_params[:callback_url] != ""
          user.callback_url = user_params[:callback_url]
        end

        user.save!

        # if role_id is exist as array
        if user_params[:role_id].kind_of?(Array) && user_params[:role_id].present?
          user.roles = Role.where("id IN (?)", user_params[:role_id].to_a)
          user.save!

        # if not array but exist
        elsif user_params[:role_id].present? && !user_params[:role_id].nil? && user_params[:role_id] != ""
          user.roles = Role.where(id: user_params[:role_id].to_i)
          user.save!

        # else use default level => MEMBER
        else
          role = Role.where(name: 'Member')
          if role.empty?
            render json: {
              error: {
                message: "Can't find user role, please contact admin to seed their database."
              }
            }, status: 500 and return
          end

          user.roles = role
          user.save!
        end
      end

      render json: {
        data: user.as_json({:show_profile => true})
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
  # @api {delete} /api/v1/admin/users/:id Delete User By Id
  # @apiName AdminDeleteUserById
  # @apiGroup Admin - User
  # @apiPermission Admin
  #
  # @apiParam {String} access_token Admin access token
  # @apiParam {Number} id User id to delete
  # =end
  def destroy
    begin
      user = nil
      if params[:id] == @current_user.id.to_s
        raise Exception.new("You can not delete your own profile. Please use /me instead.")
      end
      user = User.where(application_id: @current_user.application_id).where(id: params[:id]).first
      user.destroy

      render json: {
        data: user.as_json({:show_profile => true})
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
  # @api {delete} /api/v1/admin/users/:id/contacts Show User Contacts By Id
  # @apiDescription You can use get `/api/v1/admin/users.csv` to export using same params.
  # @apiName AdminShowUserContact
  # @apiGroup Admin - User
  # @apiPermission Admin
  #
  # @apiParam {String} access_token Admin access token
  # @apiParam {Number} id User id
  # @apiParam {String} email Filter by contact email of this user
  # @apiParam {String} fullname Filter by contact fullname of this user
  # @apiParam {String} phone_number Filter by contact phone_number of this user
  # @apiParam {Number} [page=1] Pagination number
  # =end
  def contacts
    begin
      contacts = Array.new
      user = nil

      ActiveRecord::Base.transaction do

        if params[:id].to_s == @current_user.id.to_s
          raise Exception.new("You can not see your own contact using this end-point. Please use /me instead.")
        end
        user = User.find_by(id: params[:id], application_id: @current_user.application_id)

        if user.nil?
          contacts = Array.new
        else
          contact_id = user.contacts.pluck(:contact_id)
          contacts = User.where("id IN (?)", contact_id)

          contacts = contacts.where("LOWER(email) LIKE ?", "%#{params[:email]}%") if !params[:email].nil? && params[:email] != ""
          contacts = contacts.where("LOWER(fullname) LIKE ?", "%#{params[:fullname]}%") if !params[:fullname].nil? && params[:fullname] != ""
          contacts = contacts.where("LOWER(phone_number) LIKE ?", "%#{params[:phone_number]}%") if !params[:phone_number].nil? && params[:phone_number] != ""

          contacts = contacts.as_json({:show_profile => true})

          favored_status = user.contacts.pluck(:contact_id, :is_favored)
          contacts = contacts.map do |e|
            e.merge!('is_favored' => favored_status.to_h[ e["id"] ] )
          end
        end

      end

      respond_to do |format|
        format.csv {
          attributes = %w{id fullname phone_number email gender date_of_birth}
          csv_string = CSV.generate(headers: true) do |csv|
            csv << attributes
            contacts.each do |row|
              csv << attributes.map{ |attr| row[attr] }
            end
          end

          send_data(csv_string, filename: "contacts-of-user-#{user.phone_number}_#{Date.today}.csv")
        }

        format.json {
          total = contacts.count

          if contacts.is_a?(Array)
            contacts = Kaminari.paginate_array(contacts).page(params[:page]).per(25)
          else
            contacts = contacts.page(params[:page]).per(25)
          end

          render json: {
            per_page: 25,
            total_data: total,
            data: contacts
          }
        }
      end

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
  # @api {get} /api/v1/admin/users/:id/chat_rooms Show Chat Room by User Id
  # @apiName AdminShowChatRoomByUserId
  #
  # @apiGroup Admin - User
  # @apiPermission Admin
  #
  # @apiParam {String} access_token Admin access token
	# @apiParam {Number} id User id in qisme engine
	# @apiParam {Number} page Page number
  # @apiParam {Number} limit Limit data per page
  # @apiParam {String} [start_date] Filter call logs by date. filter this by start_date and end_date. use format YYYY-MM-DD
	# @apiParam {String} [end_date] Filter call logs by date. filter this by start_date and end_date. use format YYYY-MM-DD
  # =end
  def chat_rooms
		begin
			total_page = 0
      total = 0
      params[:limit].present? ? limit = params[:limit] : limit = 25
      params[:page].present? ? page = params[:page] : page = 1
      room_name = params[:room_name]

			# find user by id and application id
			user = User.find_by(id: params[:id], application_id: @current_user.application.id)
			if user.nil?
				raise Exception.new("User not found")
      end

      if room_name.present?
        chat_rooms = user.chat_rooms.where("qiscus_room_name ILIKE ?", "%#{room_name}%")
                    .or(user.chat_rooms.where("group_chat_name ILIKE ?", "%#{room_name}%"))
      else
        chat_rooms = user.chat_rooms.all
      end

      if params[:start_date].present? && params[:end_date].present?
        start_date = params[:start_date].to_time
        end_date = params[:end_date].to_time

        chat_rooms = chat_rooms.where(created_at: start_date.beginning_of_day..end_date.end_of_day)
      end

      total = chat_rooms.count

      qiscus_room_ids = chat_rooms.pluck(:qiscus_room_id)

      if qiscus_room_ids.present? && !qiscus_room_ids.empty?
        # get rooms info from sdk
        qiscus_sdk = QiscusSdk.new(@current_user.application.app_id, @current_user.application.qiscus_sdk_secret)
        sdk_status, chat_room_sdk_info = qiscus_sdk.get_rooms_info(user.qiscus_email, qiscus_room_ids)

        if sdk_status != 200
          raise Exception.new(chat_room_sdk_info["error"]["message"])
        end

        chat_rooms_hash = ChatRoomHelper.get_user_of_chat_rooms(chat_rooms)
        chat_rooms =  ChatRoomHelper.merge_chat_room_sdk_info(chat_rooms_hash, chat_room_sdk_info)

        chat_count = chat_rooms.count
      end

      chat_rooms = Kaminari.paginate_array(chat_rooms).page(page).per(limit)

      if chat_count.present?
        total_page = (chat_count / limit.to_f).ceil
      else
        total_page = 0
      end

      render json: {
				meta: {
          limit: limit.to_i,
          page: page == nil || page.to_i < 0 ? 0 : page.to_i,
          total_page: total_page,
          total: chat_count,
        },
				data: chat_rooms
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
  # @api {get} /api/v1/admin/users/import_template Download Import User Template
  # @apiName AdminDownloadImportUserTemplate
  # @apiGroup Admin - User
  # @apiPermission Admin
  #
  # @apiParam {String} access_token Admin access token
  # =end
  def import_template
    send_file(
      "#{Rails.root}/public/files/users_import_template.csv",
      filename: "users_import_template-#{Date.today}.csv",
      type: "text/csv"
    )
  end

  # =begin
  # @apiVersion 1.0.0
  # @api {post} /api/v1/admin/users/import Import User
  # @apiName AdminImportUser
  # @apiGroup Admin - User
  # @apiPermission Admin
  #
  # @apiParam {String} access_token Admin access token
  # @apiParam {File} raw_file CSV file contains data to import (must follows import template)
  # =end
  def import
    uploaded_io = @raw_file

    begin
      application_id = @current_user.application_id
      application = Application.find(application_id)

      import = User.admin_import(uploaded_io.read, application)
      render json: {
        data: import
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
  # @api {get} /api/v1/admin/users/all List of User Without Pagination
  # @apiName AdminListofUserWithoutPagination
  # @apiGroup Admin - User
  # @apiPermission Admin
  #
  # @apiParam {String} access_token Admin access token
  # @apiParam {String} email Filter by email
  # @apiParam {String} fullname Filter by fullname
  # @apiParam {String} phone_number Filter by phone_number
  # =end
  def all
    users = User.where(application_id: @current_user.application_id).where.not(id: @current_user.id).order(created_at: :desc)

    users = users.where("LOWER(email) LIKE ?", "%#{params[:email]}%") if !params[:email].nil? && params[:email] != ""
    users = users.where("LOWER(fullname) LIKE ?", "%#{params[:fullname]}%") if !params[:fullname].nil? && params[:fullname] != ""
    users = users.where("LOWER(phone_number) LIKE ?", "%#{params[:phone_number]}%") if !params[:phone_number].nil? && params[:phone_number] != ""

    render json: {
      data: users
    }
  end

  # =begin
  # @apiVersion 1.0.0
  # @api {get} /api/v1/admin/users/officials List of Official User
  # @apiDescription You can use get `/api/v1/admin/users.csv` to export using same params.
  # @apiName AdminListofOfficialUser
  # @apiGroup Admin - User
  # @apiPermission Admin
  #
  # @apiParam {String} access_token Admin access token
  # @apiParam {String} email Filter by email
  # @apiParam {String} fullname Filter by fullname
  # @apiParam {String} phone_number Filter by phone_number
  # =end
  def officials
    begin
      users = User.where(application_id: @current_user.application_id).where.not(id: @current_user.id).order(created_at: :desc)

      # only official
      official_account_ids = UserRole.where(role_id: Role.official.id).pluck(:user_id)
      users = users.where('id IN (?)', official_account_ids)

      users = users.where("LOWER(email) LIKE ?", "%#{params[:email]}%") if !params[:email].nil? && params[:email] != ""
      users = users.where("LOWER(fullname) LIKE ?", "%#{params[:fullname]}%") if !params[:fullname].nil? && params[:fullname] != ""
      users = users.where("LOWER(phone_number) LIKE ?", "%#{params[:phone_number]}%") if !params[:phone_number].nil? && params[:phone_number] != ""


      respond_to do |format|
        format.csv {
          attributes = %w{id fullname phone_number email gender date_of_birth}
          csv_string = CSV.generate(headers: true) do |csv|
            csv << attributes
            users.each do |row|
              csv << attributes.map{ |attr| row[attr] }
            end
          end

          send_data(csv_string, filename: "users-data-#{Date.today}.csv")
        }

        format.json {
          total = users.count
          users = users.page(params[:page]).per(25)

          render json: {
            per_page: 25,
            total_data: total,
            data: users.as_json({:show_profile => true})
          }
        }
      end
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
  # @api {get} /api/v1/admin/users/officials_all List of Official User Without Pagination
  # @apiName AdminListofOfficialUserWithoutPagination
  # @apiGroup Admin - User
  # @apiPermission Admin
  #
  # @apiParam {String} access_token Admin access token
  # @apiParam {String} email Filter by email
  # @apiParam {String} fullname Filter by fullname
  # @apiParam {String} phone_number Filter by phone_number
  # =end
  def officials_all
    begin
      users = User.where(application_id: @current_user.application_id).where.not(id: @current_user.id).order(created_at: :desc)

      # only official
      official_account_ids = UserRole.where(role_id: Role.official.id).pluck(:user_id)
      users = users.where('id IN (?)', official_account_ids)

      users = users.where("LOWER(email) LIKE ?", "%#{params[:email]}%") if !params[:email].nil? && params[:email] != ""
      users = users.where("LOWER(fullname) LIKE ?", "%#{params[:fullname]}%") if !params[:fullname].nil? && params[:fullname] != ""
      users = users.where("LOWER(phone_number) LIKE ?", "%#{params[:phone_number]}%") if !params[:phone_number].nil? && params[:phone_number] != ""

      render json: {
        data: users
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
  # @api {post} /api/v1/admin/users/:id/update_avatar Update User Avatar
  # @apiName AdminUpdateUserAvatar
  # @apiGroup Admin - User
  # @apiPermission Admin
  #
  # @apiParam {String} access_token Admin access token
  # @apiParam {Number} id User id to update
  # @apiParam {File} avatar_file Picture file for new avatar
  # =end
  def update_avatar
    begin
      if params[:id] == @current_user.id.to_s
        raise Exception.new("You can not change your own profile. Please use /me instead.")
      end

      user = User.find_by(id: params[:id], application_id: @current_user.application_id)

      qiscus_sdk = QiscusSdk.new(user.application.app_id, user.application.qiscus_sdk_secret)
      url = qiscus_sdk.upload_file(@current_user.qiscus_token, @avatar_file)

      user.avatar_url = url

      render json: {
        data: user.as_json({:show_profile => true})
      }
    rescue Exception => e
      render json: {
        error: {
          message: e.message
        }
      }, status: 422 and return
    end
  end

  def send_message
    uploaded_io = @raw_file

    begin
      ActiveRecord::Base.transaction do
        message = params[:message]

        # Start read csv to phone_number
        file_path = uploaded_io.read
        csv = CSV.new(file_path, :headers => true, :encoding => 'iso-8859-1:utf-8')
        csv.each do |row|
          data = row.to_hash
          phone_number = data["phone_number"]
          SmsVerification.send_using_twilio(phone_number, message)
        end
      end
    end
    render json: {
      message: 'success send message'
    }
  end


  private
    def ensure_create_params
      params.require(:user).permit(:phone_number, :fullname, :email, :gender, :date_of_birth,
        :role_id, :is_public, :description, :avatar_file, :callback_url)
    end

    def ensure_raw_file
      @raw_file = params[:raw_file]

      render json: {
        error: {
            message: 'invalid raw file'
          }
        }, status: 422 unless @raw_file
    end

    def ensure_update_avatar_params
      @avatar_file = params[:avatar_file]

      render json: {
        status: 'fail',
        message: 'invalid avatar file'
      }, status: 422 unless @avatar_file
    end

end
