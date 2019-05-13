class Api::V1::ContactsController < ProtectedController
  before_action :authorize_user

  # =begin
  # @apiVersion 1.0.0
  # @api {get} /api/v1/contacts Contact List
  # @apiName ContactList
  # @apiGroup Contact
  #
  # @apiParam {String} access_token User access token
  # @apiParam {String} show Possible value is: `all` to show all user within this application, `contact` to show only their contact, `official` to only show official account.
  # `not_contact` to show all users thats not in contact.
  # If you don't send any parameter, it will be use previous logic, where `only` and `exclude` parameter stills work, otherwise that two parameter will not work.
  # @apiParam {Number} page Page number
  # @apiParam {Number} limit Limit
  # @apiParam {String} only Possible value is: `official`. If you use this parameter (`only=official`) you will only see official account member.
  # @apiParam {String} exclude Possible value is: `official`. If you use this parameter (`exclude=official`) you will see all contact except official account.
  # =end
  def index
    begin
      total_page = 0
      total = 0
      contacts = nil
      limit = params[:limit]
      page = params[:page]
      ActiveRecord::Base.transaction do
        # add all official user before loading contacts
        role_official_user = Role.official
        if role_official_user.nil? == false
          user_role_ids = UserRole.where(role_id: role_official_user.id).pluck(:user_id).to_a
          official_account = User.where("id IN (?)", user_role_ids).where(application_id: @current_user.application_id)
          official_account = official_account.where.not(id: @current_user.id)
          official_account = official_account.pluck(:id)

          official_account = official_account - @current_user.contacts.pluck(:contact_id)

          official_account_to_be_added = Array.new
          official_account.each do |id|
            official_account_to_be_added.push({:user_id => @current_user.id, :contact_id => id})
          end

          # add official contact
          Contact.create(official_account_to_be_added)
        end

        show = params[:show]
        if show == 'all'
          contacts = User.includes([:roles, :application]).where("users.application_id = ?", @current_user.application_id)
          contacts = contacts.where.not(fullname: nil).where.not(fullname: "") # only show contact who has complete their profile (fullname not nil)
          contacts = contacts.order(fullname: :asc)

          total = contacts.count

          # pagination only when exist
          if page.present?
            contacts = contacts.page(page)
          end

          # if limit and page present, then use kaminari pagination
          if limit.present? && page.present?
            contacts = contacts.per(limit)
          # else use limit from ActiveRecord
          elsif limit.present?
            contacts = contacts.limit(limit)
          else
            limit = 25
            contacts = contacts.limit(25)
          end

          total_page = (total / limit.to_f).ceil

        elsif show == 'contact'
          # show contact except official account and bot
          sql = <<-SQL
          contacts.contact_id NOT IN (
            SELECT user_id 
            FROM user_roles 
            WHERE role_id = ? OR role_id = ?
          )
          SQL
          contact_id = @current_user.contacts
            .where(sql, Role.official.id, Role.bot.id)
            .pluck(:contact_id)
          contacts = User.includes([:roles, :application]).where("users.application_id = ?", @current_user.application_id).where("users.id IN (?)", contact_id)
          contacts = contacts.where.not(fullname: nil).where.not(fullname: "") # only show contact who has complete their profile (fullname not nil)
          contacts = contacts.order(fullname: :asc)

          total = contacts.count

          # pagination only when exist
          if page.present?
            contacts = contacts.page(page)
          end

          # if limit and page present, then use kaminari pagination
          if limit.present? && page.present?
            contacts = contacts.per(limit)
          # else use limit from ActiveRecord
          elsif limit.present?
            contacts = contacts.limit(limit)
          else
            limit = 25
            contacts = contacts.limit(25)
          end

          total_page = (total / limit.to_f).ceil

        elsif show == 'official'
          # show contact except official account
          contact_id = @current_user.contacts.where("contacts.contact_id IN (select user_id from user_roles where role_id = ?)", Role.official.id).pluck(:contact_id)
          contacts = User.includes([:roles, :application]).where("users.application_id = ?", @current_user.application_id).where("users.id IN (?)", contact_id)
          contacts = contacts.where.not(fullname: nil).where.not(fullname: "") # only show contact who has complete their profile (fullname not nil)
          contacts = contacts.order(fullname: :asc)

          total = contacts.count

          # pagination only when exist
          if page.present?
            contacts = contacts.page(page)
          end

          # if limit and page present, then use kaminari pagination
          if limit.present? && page.present?
            contacts = contacts.per(limit)
          # else use limit from ActiveRecord
          elsif limit.present?
            contacts = contacts.limit(limit)
          else
            limit = 25
            contacts = contacts.limit(25)
          end

          total_page = (total / limit.to_f).ceil

        elsif show == 'not_contact'
          # show all users in the apps except official users and @current_user
          all_users_ids = User.where(application_id: @current_user.application_id).where.not("id IN (select user_id from user_roles where role_id = ?)", Role.official.id).where.not(id: @current_user.id).pluck(:id)
          # show user contact
          contact_ids = @current_user.contacts.where("contacts.contact_id NOT IN (select user_id from user_roles where role_id = ?)", Role.official.id).pluck(:contact_id)
          contact_ids = all_users_ids - contact_ids

          contacts = User.where(id: contact_ids, application_id: @current_user.application_id)
          contacts = contacts.where.not(fullname: nil).where.not(fullname: "") # only show contact who has complete their profile (fullname not nil)
          contacts = contacts.order(fullname: :asc)

          total = contacts.count

          # pagination only when exist
          if page.present?
            contacts = contacts.page(page)
          end

          # if limit and page present, then use kaminari pagination
          if limit.present? && page.present?
            contacts = contacts.per(limit)
          # else use limit from ActiveRecord
          elsif limit.present?
            contacts = contacts.limit(limit)
          else
            limit = 25
            contacts = contacts.limit(25)
          end

          total_page = (total / limit.to_f).ceil

        else
          # for backward compatible, limit = total
          contact_id = @current_user.contacts.pluck(:contact_id)
          contacts = User.includes([:roles, :application]).where("users.id IN (?)", contact_id)
          contacts = contacts.where.not(fullname: nil).where.not(fullname: "") # only show contact who has complete their profile (fullname not nil)
          contacts = contacts.order(fullname: :asc)
          total = contacts.count

          only = params[:only]
          if only.present? && only != ""
            if only == 'official'
              contact_id = @current_user.contacts.where("contact_id IN (select user_id from user_roles where role_id = ?)", Role.official.id).pluck(:contact_id)
              contacts = User.includes([:roles, :application]).where("application_id = ?", @current_user.application_id).where("users.id IN (?)", contact_id)
              contacts = contacts.where.not(fullname: nil).where.not(fullname: "") # only show contact who has complete their profile (fullname not nil)
              contacts = contacts.order(fullname: :asc)
              total = contacts.count
              if !page.present? && !limit.present?
                limit = total
              end
            end
          end

          exclude = params[:exclude]
          if exclude.present? && exclude != ""
            if exclude == 'official'
              contact_id = @current_user.contacts.where.not("contact_id IN (select user_id from user_roles where role_id = ?)", Role.official.id).pluck(:contact_id)
              contacts = User.includes([:roles, :application]).where("application_id = ?", @current_user.application_id).where("users.id IN (?)", contact_id)
              contacts = contacts.where.not(fullname: nil).where.not(fullname: "") # only show contact who has complete their profile (fullname not nil)
              contacts = contacts.order(fullname: :asc)
              total = contacts.count
              if !page.present? && !limit.present?
                limit = total
              end
            end
          end

          # pagination only when exist
          if page.present?
            contacts = contacts.page(page)
          end

          # if limit and page present, then use kaminari pagination
          if limit.present? && page.present?
            contacts = contacts.per(limit)
          # else use limit from ActiveRecord
          elsif limit.present?
            contacts = contacts.limit(limit)
          else
            limit = total
            contacts = contacts.limit(limit)
          end

          if limit == 0
            total_page = 0
          else
            total_page = (total / limit.to_f).ceil
          end
        end

        contacts = contacts.map(&:as_contact_json)

        contact_id = @current_user.contacts.pluck(:contact_id)
        favored_status = @current_user.contacts.pluck(:contact_id, :is_favored)
        contacts = contacts.map do |e|
          # is contact is always true since this will only load contact of this user
          is_contact = contact_id.include?(e["id"])
          is_favored = favored_status.to_h[ e["id"] ] == nil ? false : favored_status.to_h[ e["id"] ]
          e.merge!('is_favored' => is_favored, 'is_contact' => is_contact )
        end

      end

      render json: {
        meta: {
          limit: limit.to_i,
          page: page == nil || page.to_i < 0 ? 0 : page.to_i,
          total_page: total_page,
          total: total,
        },
        data: contacts
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

    rescue Exception => e
      render json: {
        error: {
          message: e.message
        }
      }, status: 422 and return
    end
  end

  # =begin
  # @apiVersion 1.0.0
  # @api {post} /api/v1/contacts Add Contact
  # @apiDescription Add new contact
  # @apiName AddContact
  # @apiGroup Contact
  #
  # @apiParam {String} access_token User access token
  # @apiParam {Number} contact_id User id to be add as contact
  # =end
  def create
    begin

      if !params[:contact_id].present? || params[:contact_id] == ""
        raise Exception.new("Contact id must be present.")
      end

      if params[:contact_id].to_s == @current_user.id.to_s
        raise Exception.new("You can not add your self as contact.")
      end

      user = nil
      ActiveRecord::Base.transaction do
        contact_id = User.find_by(id: params[:contact_id], application_id: @current_user.application.id)

        if contact_id.nil?
          raise Exception.new("Contact id is not found.")
        end

        contact = Contact.find_by(user_id: @current_user.id, contact_id: contact_id.id)

        if contact.nil?
          contact = Contact.new
          contact.user_id = @current_user.id
          contact.contact_id = contact_id.id
          contact.save
          # send new contact push notification
          new_contacts_pn = [[@current_user.id, contact_id.id]]
          ContactPushNotificationJob.perform_later(new_contacts_pn)
        else
          raise Exception.new("User already in your contact.")
        end

        # make added contact as adder's contact
        # if A add B as contact, A will be added as contact to B. A (add)-> B = A <-> B
        # delete this block
        added_contact = Contact.find_by(user_id: contact_id.id, contact_id: @current_user.id)

        if added_contact.nil?
          added_contact = Contact.new
          added_contact.user_id = contact_id.id
          added_contact.contact_id = @current_user.id
          added_contact.save
        end
        # till this block to remove dependent contact invitation

        # get the user detail
        user = User.find(contact.contact_id)
        user = user.as_contact_json({:show_profile => false})
      end

      # render user detail
      render json: {
        data: user
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

    rescue Exception => e
      render json: {
        error: {
          message: e.message
        }
      }, status: 422 and return
    end
  end

  # =begin
  # @apiVersion 1.0.0
  # @api {delete} /api/v1/contacts/delete_contact Delete Contact
  # @apiDescription Delete contact
  # @apiName DeleteContact
  # @apiGroup Contact
  #
  # @apiParam {String} access_token User access token
  # @apiParam {Number} contact_id User id to be deleted as contact
  # =end
  def delete_contact
    begin
      if !params[:contact_id].present? || params[:contact_id] == ""
        raise Exception.new("Contact id can not be empty string.")
      end

      contact_user = nil
      ActiveRecord::Base.transaction do
        current_user_id = @current_user.id
        contact_user = User.find(params[:contact_id])

        contact = Contact.find_by(user_id: current_user_id, contact_id: contact_user.id)

        if contact.nil? == false
          contact.destroy
        end

        contact_user = contact_user.as_contact_json({:show_profile => false})
      end

      render json: {
        data: contact_user
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

    rescue Exception => e
      render json: {
        error: {
          message: e.message
        }
      }, status: 422 and return
    end
  end

  # =begin
  # @apiVersion 1.0.0
  # @api {post} /api/v1/contacts/search Search User
  # @apiDescription Search user to be added as contact
  # @apiName SearchUser
  # @apiGroup Contact
  #
  # @apiParam {String} access_token User access token
  # @apiParam {String} phone_number Registered phone number (must be include country code)
  # =end
  def search
    begin
      phone_number = params[:phone_number].delete(' ')

      if !phone_number.present? || phone_number == "" || phone_number.length < 9
        raise Exception.new("Minimum phone number is 9")
      end

      # valid_phone_number = Phony.plausible?(phone_number)
      # if valid_phone_number == false
      #   raise Exception.new("Phone number format is invalid.")
      # end

      user = nil
      ActiveRecord::Base.transaction do
        application = @current_user.application

        # search using phone_number
        user1 = User.where(application_id: application.id, phone_number: phone_number)
        # search using secondary_phone_number
        user2 = User.where(application_id: application.id, secondary_phone_number: phone_number)

        user = user1 + user2
        user = user.uniq
        user = user.first # only return first user

        if user.nil? == false

          # if user has not complete their profile, then return error
          # disable, user can be found even they has not complete their fullname
          # if user.fullname.nil? || user.fullname == ""
          #   raise Exception.new("User has not complete their profile yet.")
          # end

          exist_contact = Contact.find_by(user_id: @current_user.id, contact_id: user.id)
          if exist_contact.nil? == false # already in contact
            raise Exception.new("User already in your contact.")
          end
        else
          # raise Exception.new("User not found.")
          render json: {
            error: {
              message: "User not found."
            }
          }, status: 404 and return
        end
      end

      render json: {
        data: user.as_contact_json({:show_profile => false})
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

    rescue Exception => e
      render json: {
        error: {
          message: e.message
        }
      }, status: 422 and return
    end
  end

  # =begin
  # @apiVersion 1.0.0
  # @api {post} /api/v1/contacts/search_by_qiscus_email Search User by Qiscus Email
  # @apiDescription Search user to be added as contact using qiscus email, only used in particular condition, not for adding contact
  # @apiName SearchUserByQiscusEmail
  # @apiGroup Contact
  #
  # @apiParam {String} access_token User access token
  # @apiParam {String} qiscus_email User qiscus email
  # =end
  def search_by_qiscus_email
    begin
      qiscus_email = params[:qiscus_email].delete(' ')

      if !qiscus_email.present? || qiscus_email == ""
        raise Exception.new("Qiscus email can't be empty.")
      end

      user = nil
      ActiveRecord::Base.transaction do
        application = @current_user.application

        user = User.find_by(application_id: application.id, qiscus_email: qiscus_email)

        if user.nil?
          raise Exception.new("User not found.")
        end
      end

      render json: {
        data: user.as_contact_json({:show_profile => false})
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

    rescue Exception => e
      render json: {
        error: {
          message: e.message
        }
      }, status: 422 and return
    end
  end

  # =begin
  # @apiVersion 1.0.0
  # @api {post} /api/v1/contacts/search_by_email Search User by Email
  # @apiDescription Search user by registered email to be added as contact
  # @apiName SearchUserByEmail
  # @apiGroup Contact
  #
  # @apiParam {String} access_token User access token
  # @apiParam {String} email Registered email
  # =end
  def search_by_email
    begin
      email = params[:email].delete(' ')

      if !email.present? || email == ""
        raise Exception.new("Email can't be empty.")
      end

      user = nil
      ActiveRecord::Base.transaction do
        application = @current_user.application

        user = User.find_by(application_id: application.id, email: email)

        if user.nil? == false

          # if user has not complete their profile, then return error
          # disable, user can be found even they has not complete their fullname
          # if user.fullname.nil? || user.fullname == ""
          #   raise Exception.new("User has not complete their profile yet.")
          # end

          exist_contact = Contact.find_by(user_id: @current_user.id, contact_id: user.id)
          if exist_contact.nil? == false # already in contact
            raise Exception.new("User already in your contact.")
          end
        else
          raise Exception.new("User not found.")
        end
      end

      render json: {
        data: user.as_contact_json({:show_profile => false})
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

    rescue Exception => e
      render json: {
        error: {
          message: e.message
        }
      }, status: 422 and return
    end
  end

  # =begin
  # @apiVersion 1.0.0
  # @api {post} /api/v1/contacts/search_by_all_field Search User by All Field
  # @apiDescription Search user by all field such as fullname, phone_number, qiscus,
  # qiscus_email and existing additional_infos
  # @apiName SearchUserByAllField
  # @apiGroup Contact
  #
  # @apiParam {String} access_token User access token
  # @apiParam {String} query Search query. Support multiple value that separated by space. If query is nil, it'll show all users in application and filtered by "show" parameter used.
  # Example = Heru Bisma
  # @apiParam {String} show Possible value is: `all` to show all user within this application in search results, `contact` to show only their contact in search results, `not_contact` to show users thats not in contact in search results.
  # If you don't send any parameter, it will be use previous logic, where `only` and `exclude` parameter stills work, otherwise that two parameter will not work.
  # @apiParam {Number} page Page number
  # @apiParam {Number} limit Limit
  # =end
  def search_by_all_field
    begin
      total_page = 0
      total = 0
      limit = params[:limit]
      page = params[:page]
      users = nil

      query = params[:query]
      ActiveRecord::Base.transaction do
        application = @current_user.application

        if !query.present? || query == ""
          # if query is nil, show all users in the @current_user application
          users = User.where(application_id: application.id)
        else
          # split query by space because this api can search user by multiple value
          queries = query.split(" ")

          queries.each do |query|
            query.replace("%#{query}%")
          end

          user_ids = UserAdditionalInfo.where("user_additional_infos.value ILIKE ANY (array[?])", queries).pluck(:user_id)
          application_users = application.users
          users = application_users.where("phone_number ILIKE ANY (array[?])", queries)
          users = users.or(application_users.where("fullname ILIKE ANY (array[?])", queries))
          users = users.or(application_users.where("email ILIKE ANY (array[?])", queries))
          users = users.or(application_users.where("qiscus_email ILIKE ANY (array[?])", queries))
          users = users.or(application_users.where(id: user_ids))
        end

        # exclude @current_user on search result
        users = users.where.not(id: @current_user.id)

        show = params[:show]
        if show == 'all'
          # show all users including official users
          users = users

        elsif show == 'contact'
          # show @current_user contact excluding @current_user and official users
          # show user_ids and contact_ids. and do users_ids - contact_ids
          user_ids = users.pluck(:id)
          # show all users in the apps except official users and @current_user
          all_users_ids = User.where(application_id: @current_user.application_id).pluck(:id)
          # show user contact
          contact_ids = @current_user.contacts.where("contacts.contact_id NOT IN (select user_id from user_roles where role_id = ?)", Role.official.id).pluck(:contact_id)
          not_contact_ids = all_users_ids - contact_ids
          user_ids = user_ids - not_contact_ids

          # show the users detail that has been substracted before
          users = User.includes([:roles, :application]).where("users.application_id = ?", @current_user.application_id).where("users.id IN (?)", user_ids)

        elsif show == 'not_contact'
          # show @current_user that's not_contact, excluding @current_user and official users
          # show user_ids and contact_ids. and do users_ids - contact_ids
          user_ids = users.pluck(:id)
          # contact_ids = @current_user.contacts.where("contact_id NOT IN (select user_id from user_roles where role_id = ?)", Role.official.id).pluck(:contact_id)
          contact_ids = @current_user.contacts.pluck(:contact_id)
          user_ids = user_ids - contact_ids

          # show the users detail that has been substracted before
          users = User.includes([:roles, :application]).where("users.application_id = ?", @current_user.application_id).where("users.id IN (?)", user_ids)

        else
          # show all users
          users = users

        end

        users = users.where.not(fullname: nil).where.not(fullname: "") # only show contact who has complete their profile (fullname not nil)
        users = users.order(fullname: :asc)
        total = users.count

        # pagination only when exist
        if page.present?
          users = users.page(page)
        end

        # if limit and page present, then use kaminari pagination
        if limit.present? && page.present?
          users = users.per(limit)
        # else use limit from ActiveRecord
        elsif limit.present?
          users = users.limit(limit)
        else
          limit = 25
          users = users.limit(25)
        end

        total_page = (total / limit.to_f).ceil

        users = users.map(&:as_contact_json)

        contact_id = @current_user.contacts.pluck(:contact_id)
        favored_status = @current_user.contacts.pluck(:contact_id, :is_favored)
        users = users.map do |e|
          # is contact is always true since this will only load contact of this user
          is_contact = contact_id.include?(e["id"])
          is_favored = favored_status.to_h[ e["id"] ] == nil ? false : favored_status.to_h[ e["id"] ]
          e.merge!('is_favored' => is_favored, 'is_contact' => is_contact )
        end
      end

      render json: {
        meta: {
          limit: limit.to_i,
          page: page == nil || page.to_i < 0 ? 0 : page.to_i,
          total_page: total_page,
          total: total,
        },
        data: users
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

    rescue Exception => e
      render json: {
        error: {
          message: e.message
        }
      }, status: 422 and return
    end
  end

  def search_bot
    begin
      username = params[:username].delete(' ')

      if !username.present? || username == ""
        raise Exception.new("Username can't be empty.")
      end

      user = nil

      ActiveRecord::Base.transaction do
        user = User.joins(:bot)
          .where("bots.username = ? ", username)
          .first()

        if user.nil? == false
          exist_contact = Contact.find_by(user_id: @current_user.id, contact_id: user.id)
          if exist_contact.nil? == false # already in contact
            raise Exception.new("Bot already in your contact.")
          end
        else
          raise Exception.new("Bot not found.")
        end
      end

      # bot username inside phone_number
      # because bot not used phone_number
      user[:phone_number] = user.bot.username
      
      render json: {
        data: user
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

    rescue Exception => e
      render json: {
        error: {
          message: e.message
        }
      }, status: 422 and return
    end
  end

  def bot
    # @current_user = User.where(id: 61).first
    begin

      if !params[:contact_id].present? || params[:contact_id] == ""
        raise Exception.new("Contact id must be present.")
      end

      if params[:contact_id].to_s == @current_user.id.to_s
        raise Exception.new("You can not add your self as contact.")
      end

      if !params[:password].present?
        raise Exception.new("Password must be present.")
      end

      user = nil
      ActiveRecord::Base.transaction do
        contact_id = User.find_by(id: params[:contact_id], application_id: @current_user.application.id)

        if contact_id.nil?
          raise Exception.new("Contact id is not found.")
        end

        contact = Contact.find_by(user_id: @current_user.id, contact_id: contact_id.id)

        if contact.nil?
          contact = Contact.new
          contact.user_id = @current_user.id
          contact.contact_id = contact_id.id
          contact.save
          # send new contact push notification
          new_contacts_pn = [[@current_user.id, contact_id.id]]
          ContactPushNotificationJob.perform_later(new_contacts_pn)
        else
          raise Exception.new("User already in your contact.")
        end

        # make added contact as adder's contact
        # if A add B as contact, A will be added as contact to B. A (add)-> B = A <-> B
        # delete this block
        added_contact = Contact.find_by(user_id: contact_id.id, contact_id: @current_user.id)

        if added_contact.nil?
          added_contact = Contact.new
          added_contact.user_id = contact_id.id
          added_contact.contact_id = @current_user.id
          added_contact.save
        end
        # till this block to remove dependent contact invitation

        # get the user detail
        user = User.find(contact.contact_id)
        bot = Bot.where(user_id: user.id).first
        if bot.nil?
          raise Exception.new("Bot not found!")
        end

        creator = User.where(id: bot.user_id_creator).first
        if creator.nil?
          raise Exception.new("Bot creator not found!")
        end

        check_password = Bot.check_password(params, bot.password_digest)
        if check_password == true
          user = user.as_contact_json({:show_profile => false})
        else
          raise Exception.new("Wrong Password!, for password information please contact #{user.fullname} creator : #{creator.fullname}")
        end
      end

      # render user detail
      render json: {
        data: user
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

    rescue Exception => e
      render json: {
        error: {
          message: e.message
        }
      }, status: 422 and return
    end
  end

end
