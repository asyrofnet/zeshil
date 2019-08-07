class Api::V2::ContactsController < ProtectedController
    before_action :authorize_user
  
    # =begin
    # @apiVersion 2.0.0
    # @api {get} /api/v2/contacts Contact List V2
    # @apiName ContactListV2
    # @apiGroup Contact
    #
    # @apiParam {String} access_token User access token
    # @apiParam {Number} page Page number optional
    # @apiParam {Number} limit Limit optional
    # =end
    def index
      begin
        total_page = 0
        total = 0
        contacts = nil
        limit = params[:limit]
        page = params[:page]
        ActiveRecord::Base.transaction do
         
            contact_id = @current_user.contacts.where(is_active: true).pluck(:contact_id)
            contacts = User.includes([:roles, :application, :user_additional_infos]).where("users.id IN (?)", contact_id)
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
              limit = total
              contacts = contacts.limit(limit)
            end
  
            if limit == 0
              total_page = 0
            else
              total_page = (total / limit.to_f).ceil
            end
          
          
          contacts = contacts.map(&:as_contact_json)
  
          contact_id = @current_user.contacts.pluck(:contact_id)
          
          favored_status = @current_user.contacts.pluck(:contact_id, :is_favored)
          phone_book = @current_user.contacts.pluck(:contact_id, :contact_name)
          contact_hash = phone_book.to_h
          contacts = contacts.map do |e|
            # is contact is always true since this will only load contact of this user
            is_contact = contact_id.include?(e["id"])
            is_favored = favored_status.to_h[ e["id"] ] == nil ? false : favored_status.to_h[ e["id"] ]
            contact_name = contact_hash[ e["id"] ]
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
  
      rescue => e
        render json: {
          error: {
            message: e.message,
            class: e.class.name
          }
        }, status: 422 and return
      end
    end

    # =begin
    # @apiVersion 2.0.0
    # @api {get} /api/v2/contacts/discover Discover V2
    # @apiName DiscoverV2
    # @apiDescription get account for Discover. Use this if dev need different API
    # @apiGroup Contact
    #
    # @apiParam {String} access_token User access token
    # @apiParam {Number} page Page number
    # @apiParam {Number} limit Limit
    # =end
    def discover
      total_page = 0
      total = 0
      contacts = nil
      limit = params[:limit]
      page = params[:page]
      ActiveRecord::Base.transaction do
        sql = <<-SQL
            contacts.contact_id IN (
              SELECT user_id 
              FROM user_roles 
              WHERE role_id = ?
            )
            SQL
            bot_id = @current_user.contacts
              .where(sql, Role.bot.id)
              .pluck(:contact_id)
            role_official_user = Role.official
            offcial_id = []
            if role_official_user.nil? == false
              user_role_ids = UserRole.where(role_id: role_official_user.id).pluck(:user_id).to_a
              official_account = User.where("id IN (?)", user_role_ids).where(application_id: @current_user.application_id)
              official_account = official_account.where.not(id: @current_user.id)
              offcial_id = official_account.pluck(:id)
            end
            contact_id = bot_id + offcial_id
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

            contacts = contacts.map(&:as_contact_json)
  
          real_contact_id = @current_user.contacts.where(is_active:true).pluck(:contact_id)
          favored_status = @current_user.contacts.pluck(:contact_id, :is_favored)
          phone_book = @current_user.contacts.pluck(:contact_id, :contact_name)
          contact_hash = phone_book.to_h
          contacts = contacts.map do |e|
            is_contact = real_contact_id.include?(e["id"])
            is_favored = favored_status.to_h[ e["id"] ] == nil ? false : favored_status.to_h[ e["id"] ]
            contact_name = contact_hash[ e["id"] ]
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
  
      rescue => e
        render json: {
          error: {
            message: e.message,
            class: e.class.name
          }
        }, status: 422 and return
    end

    # =begin
    # @apiVersion 2.0.0
    # @api {post} /api/v2/contacts/add_or_update Add or Update Contact V2
    # @apiName AddOrUpdateContactV2
    # @apiDescription Add or Update contacts.
    # @apiGroup Contact
    #
    # @apiParam {String} access_token User access token
    # @apiParam {Array} contact[] Array of object of contacts with phone number and contact name, for instance: `contact:[{"phone_number":"+62832421","contact_name":"hello"},{"phone_number":"+62832424","contact_name":"world"}]`
    # =end
    def add_or_update
      begin
        if !params[:contact].present?
          render json: {
            data: []
          } and return
        end

        if params[:contact].kind_of?(Array) && params[:contact].present?
          current_user_phone_number = @current_user.phone_number
          phone_numbers = Array.new
          phone_books = Hash.new
          params[:contact].each do | contact |
  
            phone_number = contact["phone_number"]
            phone_number = phone_number.strip().delete(' ') # remove all spaces
            phone_number = phone_number.strip().delete('-') # remove dash
            phone_number = phone_number.gsub(/[[:space:]]/, '')
  
            if phone_number.start_with?("8")
              phone_number = @current_user.country_code + phone_number
            elsif phone_number.start_with?("0")
              phone_number = phone_number[1..-1]
              phone_number = @current_user.country_code + phone_number
            end
             phone_numbers.push(phone_number)
             phone_books[phone_number] = contact["contact_name"]
          end

          contacts = nil
          ActiveRecord::Base.transaction do
            users = User.where("LOWER(phone_number) IN (?)", phone_numbers)
            users = users.where(application_id: @current_user.application.id) # only looking for user where has same application id
            users = users.where.not(phone_number: current_user_phone_number) # exclude ownself to be added
            new_contacts = Array.new
            #update old contacts with new name
            users.each do |user|
              contact = Contact.find_by(user_id: @current_user.id, contact_id: user.id)
              phone = user.phone_number
              if !contact.nil?
                if (contact.contact_name != phone_books[phone]) || (!contact.is_active)
                  contact.update!(contact_name: phone_books[phone],is_active:true)
                end
              else
                new_contacts.push({:user_id => @current_user.id, :contact_id => user.id, :contact_name => phone_books[phone]})
              end
            end
  
            # add new contact
            Contact.create(new_contacts) if !new_contacts.empty?
            
            contacts = users.order(fullname: :asc)
    
              contacts = contacts.as_json({:show_profile => true})
    
              favored_status = @current_user.contacts.pluck(:contact_id, :is_favored)
              contacts = contacts.map do |e|
                contact_name = phone_books[e["phone_number"]] || e["fullname"]
                # is contact is always true since this will only load contact of this user
                e.merge!('is_favored' => favored_status.to_h[ e["id"] ], 'is_contact' => true, "fullname" => contact_name )
              end
              render json: {
                data: contacts,
                # phone_numbers_not_valid: phone_numbers_not_valid
                          phone_numbers: phone_numbers
              }
          end
        else
          raise InputError.new("Contact must be an array of object.")
        end

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
      rescue ActiveRecord::RecordNotUnique => e
        render json: {
          error: {
            message: "Duplicate request",
            class: InputError.name
          }
      }, status: 422 and return
      rescue => e
        render json: {
          error: {
            message: e.message,
            class: e.class.name
          }
        }, status: 422 and return

      end
    end

    # =begin
    # @apiVersion 2.0.0
    # @api {post} /api/v2/contacts/remove Remove Contact V2
    # @apiName RemoveContactV2
    # @apiDescription Remove contacts.
    # @apiGroup Contact
    #
    # @apiParam {String} access_token User access token
    # @apiParam {Array} phone_number[] Array of normalized phone number, for instance: `phone_number[]=+62...&phone_number[]=+62...`
    # =end
    def remove
      begin
        if !params[:phone_number].present?
          render json: {
            data: []
          } and return
        end

        if params[:phone_number].kind_of?(Array) && params[:phone_number].present?
          current_user_phone_number = @current_user.phone_number
          phone_numbers = Array.new
          params[:phone_number].each do | phone_number |
  
            phone_number = phone_number.strip().delete(' ') # remove all spaces
            phone_number = phone_number.strip().delete('-') # remove dash
            phone_number = phone_number.gsub(/[[:space:]]/, '')
  
            if phone_number.start_with?("8")
              phone_number = @current_user.country_code + phone_number
            elsif phone_number.start_with?("0")
              phone_number = phone_number[1..-1]
              phone_number = @current_user.country_code + phone_number
            end
             phone_numbers.push(phone_number)
          end

          contacts = nil
          ActiveRecord::Base.transaction do
            users = User.where("LOWER(phone_number) IN (?)", phone_numbers)
            users = users.where(application_id: @current_user.application.id) # only looking for user where has same application id
            users_ids = users.where.not(phone_number: current_user_phone_number).pluck(:id) # exclude ownself to be added
            contacts = Contact.where(user_id: @current_user.id, contact_id: users_ids)
            contacts.update_all(is_active:false)
            
            contacts = users.order(fullname: :asc)
    
              contacts = contacts.as_json({:show_profile => true})
    
              favored_status = @current_user.contacts.pluck(:contact_id, :is_favored)
              contacts = contacts.map do |e|
                # is contact is always true since this will only load contact of this user
                e.merge!('is_favored' => favored_status.to_h[ e["id"] ], 'is_contact' => false )
              end
              render json: {
                data: contacts,
                # phone_numbers_not_valid: phone_numbers_not_valid
                          phone_numbers: phone_numbers
              }
          end
        else
          raise InputError.new("phone_number must be an array of phone numbers.")
        end

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
            message: e.message,
            class: e.class.name
          }
        }, status: 422 and return

      end
    end

    
 
end
  