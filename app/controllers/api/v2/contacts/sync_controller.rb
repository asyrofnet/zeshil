class Api::V2::Contacts::SyncController < ProtectedController
    before_action :authorize_user
  
    # =begin
    # @apiVersion 2.0.0
    # @api {post} /api/v2/contacts/sync Sync Contact V2
    # @apiDescription sync all phone number in user phone contact to be contact in qisme application
    # client (mobile) will post an array of phone number,
    # qisme engine will return all contact included added contact
    #
    # @apiName SyncPhoneContactV2
    # @apiGroup Contact
    #
    # @apiParam {String} access_token User access token
    # @apiParam {Array} contact[] Array of object of contacts with phone number and contact name, for instance: `contact:[{"phone_number":"+62832421","contact_name":"hello"},{"phone_number":"+62832424","contact_name":"world"}]`
    # =end
    def create
      begin
        if !params[:contact].present?
          raise InputError.new("Contact must be an array of object.")
        end
  
        if params[:contact].kind_of?(Array) && params[:contact].present?
          current_user_phone_number = @current_user.phone_number # this should has been normalized in registration process
          current_user_secondary_phone_number = @current_user.secondary_phone_number # this should has been normalized in registration process
          # default_country_number = PhonyRails.country_code_from_number(current_user_phone_number)
          #
          # if default_country_number == "" || default_country_number.nil?
          #   default_country_number = "62" # fallback country code if user is not registered by phone number
          # end
  
          phone_numbers = Array.new
          phone_books = Hash.new
          params[:contact].each do | contact |
            # normalized_phone_number = PhonyRails.normalize_number(phone_number, default_country_number: default_country_number)
  
            # no need to use plausible for number 13 digits can be used
            # if PhonyRails.plausible_number?(normalized_phone_number)
            #   phone_numbers.push(normalized_phone_number)
            # else
            #   phone_numbers_not_valid.push(normalized_phone_number)
            # end
            #
            phone_number = contact["phone_number"]
            phone_number = phone_number.strip().delete(' ') # remove all spaces
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

            phone_numbers = phone_numbers.uniq
            users = User.where("LOWER(phone_number) IN (?)", phone_numbers)
            users = users.where(application_id: @current_user.application.id) # only looking for user where has same application id
            users = users.where.not(phone_number: current_user_phone_number) # exclude ownself to be added
            users = users.pluck(:id) # it user founded using phone_number
  
            users_2 = User.where("LOWER(secondary_phone_number) IN (?)", phone_numbers)
            users_2 = users_2.where(application_id: @current_user.application.id) # only looking for user where has same application id
            users_2 = users_2.where.not(secondary_phone_number: current_user_secondary_phone_number) # exclude ownself to be added
            users_2 = users_2.pluck(:id) # it user founded using secondary_phone_number
  
            users = users + users_2
            
            # now looking for user where not in contact
            already_been_in_contacts = @current_user.contacts.where("contacts.contact_id IN (?)", users).pluck(:contact_id)
            bot_ids = []
            if Role.bot.present?
              bot_ids = UserRole.where(role: Role.bot).pluck(:user_id)
            end
            protected_ids_from_deactivate = already_been_in_contacts + bot_ids
            #DEACTIVATE CURRENT USER CONTACTS EXCEPT THE ONE ON QUERY AND BOT
            if !protected_ids_from_deactivate.empty?
              @current_user.contacts.where.not("contacts.contact_id IN (?)", protected_ids_from_deactivate).update_all(is_active:false)
            else
              @current_user.contacts.update_all(is_active:false)
            end
            
              # contact to be added is only user where not in contact list
            new_contacts_to_be_added = users - already_been_in_contacts
            new_contacts_to_be_added = new_contacts_to_be_added.uniq
  
            ContactCreateJob.perform_later(@current_user,already_been_in_contacts,new_contacts_to_be_added,phone_books)
            # last, load all current contact of the user
            contact_id = @current_user.contacts.where(is_active:true).pluck(:contact_id)
            contacts = User.where("id IN (?)", contact_id)
            contacts = contacts.order(fullname: :asc)
  
            contacts = contacts.as_json({:show_profile => true})
            
            favored_status = @current_user.contacts.pluck(:contact_id, :is_favored)
            contacts = contacts.map do |e|
              contact_name = phone_books[e["phone_number"]] || e["fullname"]
              # is contact is always true since this will only load contact of this user
              e.merge!('is_favored' => favored_status.to_h[ e["id"] ], 'is_contact' => true, "fullname" => contact_name )
            end
          end
          total = contacts.length
          render json: {
            total: total,
            data: contacts,
            phone_numbers: phone_numbers
          }
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
  
  end