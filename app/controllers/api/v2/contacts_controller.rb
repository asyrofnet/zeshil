class Api::V2::ContactsController < ProtectedController
    before_action :authorize_user
  
    # =begin
    # @apiVersion 2.0.0
    # @api {get} /api/v2/contacts Contact List V2
    # @apiName ContactListV2
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
            contacts = User.includes([:roles, :application,:user_additional_infos]).where("users.application_id = ?", @current_user.application_id)
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
              .where(is_active: true)
              .where(sql, Role.official.id, Role.bot.id)
              .pluck(:contact_id)
            contacts = User.includes([:roles, :application,:user_additional_infos]).where("users.application_id = ?", @current_user.application_id).where("users.id IN (?)", contact_id)
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
            contact_id = @current_user.contacts.where(is_active: true).where("contacts.contact_id IN (select user_id from user_roles where role_id = ?)", Role.official.id).pluck(:contact_id)
            contacts = User.includes([:roles, :application,:user_additional_infos]).where("users.application_id = ?", @current_user.application_id).where("users.id IN (?)", contact_id)
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
            contact_ids = @current_user.contacts.where(is_active: true).where("contacts.contact_id NOT IN (select user_id from user_roles where role_id = ?)", Role.official.id).pluck(:contact_id)
            contact_ids = all_users_ids - contact_ids
  
            contacts = User.where(id: contact_ids, application_id: @current_user.application_id)
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
            contact_id = @current_user.contacts.where(is_active: true).pluck(:contact_id)
            contacts = User.includes([:roles, :application, :user_additional_infos]).where("users.id IN (?)", contact_id)
            contacts = contacts.order(fullname: :asc)
            total = contacts.count
  
            only = params[:only]
            if only.present? && only != ""
              if only == 'official'
                contact_id = @current_user.contacts.where(is_active: true).where("contact_id IN (select user_id from user_roles where role_id = ?)", Role.official.id).pluck(:contact_id)
                contacts = User.includes([:roles, :application, :user_additional_infos]).where("application_id = ?", @current_user.application_id).where("users.id IN (?)", contact_id)
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
                contact_id = @current_user.contacts.where(is_active: true).where.not("contact_id IN (select user_id from user_roles where role_id = ?)", Role.official.id).pluck(:contact_id)
                contacts = User.includes([:roles, :application, :user_additional_infos]).where("application_id = ?", @current_user.application_id).where("users.id IN (?)", contact_id)
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
          phone_book = @current_user.contacts.pluck(:contact_id, :contact_name)
          contacts = contacts.map do |e|
            # is contact is always true since this will only load contact of this user
            is_contact = contact_id.include?(e["id"])
            is_favored = favored_status.to_h[ e["id"] ] == nil ? false : favored_status.to_h[ e["id"] ]
            contact_name = phone_book.to_h[ e["id"] ]
            if contact_name.present?
              e.merge!("fullname" => contact_name )
            end
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
 
end
  