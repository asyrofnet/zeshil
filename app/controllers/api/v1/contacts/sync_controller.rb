class Api::V1::Contacts::SyncController < ProtectedController
  before_action :authorize_user

  # =begin
  # @apiVersion 1.0.0
  # @api {post} /api/v1/contacts/sync Sync Contact From Phone Book
  # @apiDescription sync all phone number in user phone contact to be contact in qisme application
  # client (mobile) will post an array of phone number,
  # qisme engine will return all contact included added contact
  #
  # @apiName SyncPhoneContact
  # @apiGroup Contact
  #
  # @apiParam {String} access_token User access token
  # @apiParam {Array} phone_number[] Array of normalized phone number, for instance: `phone_number[]=+62...&phone_number[]=+62...`
  # =end
  def create
    begin
      if !params[:phone_number].present?
        render json: {
          data: []
        } and return
      end

      if params[:phone_number].kind_of?(Array) && params[:phone_number].present?
        current_user_phone_number = @current_user.phone_number # this should has been normalized in registration process
        current_user_secondary_phone_number = @current_user.secondary_phone_number # this should has been normalized in registration process
        # default_country_number = PhonyRails.country_code_from_number(current_user_phone_number)
        #
        # if default_country_number == "" || default_country_number.nil?
        #   default_country_number = "62" # fallback country code if user is not registered by phone number
        # end

        phone_numbers = Array.new
        phone_numbers_not_valid = Array.new

        params[:phone_number].each do | phone_number |
          # normalized_phone_number = PhonyRails.normalize_number(phone_number, default_country_number: default_country_number)

          # no need to use plausible for number 13 digits can be used
          # if PhonyRails.plausible_number?(normalized_phone_number)
          #   phone_numbers.push(normalized_phone_number)
          # else
          #   phone_numbers_not_valid.push(normalized_phone_number)
          # end
          #
          phone_number = phone_number.strip().delete(' ') # remove all spaces
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
          users = users.where.not(fullname: nil).where.not(fullname: "") # only show contact who has complete their profile (fullname not nil)
          users = users.where(application_id: @current_user.application.id) # only looking for user where has same application id
          users = users.where.not(phone_number: current_user_phone_number) # exclude ownself to be added
          users = users.pluck(:id) # it user founded using phone_number

          users_2 = User.where("LOWER(secondary_phone_number) IN (?)", phone_numbers)
          users_2 = users_2.where.not(fullname: nil).where.not(fullname: "") # only show contact who has complete their profile (fullname not nil)
          users_2 = users_2.where(application_id: @current_user.application.id) # only looking for user where has same application id
          users_2 = users_2.where.not(secondary_phone_number: current_user_secondary_phone_number) # exclude ownself to be added
          users_2 = users_2.pluck(:id) # it user founded using secondary_phone_number

          users = users + users_2

          # now looking for user where not in contact
          already_been_in_contacts = @current_user.contacts.where("contacts.contact_id IN (?)", users).pluck(:contact_id)
          # contact to be added is only user where not in contact list
          new_contacts_to_be_added = users - already_been_in_contacts
          new_contacts_to_be_added = new_contacts_to_be_added.uniq

          # now add to the contact
          new_contacts = Array.new
          new_contacts_pn = Array.new
          new_contacts_to_be_added.each do |id|
            # double check if user already been in contact.
            # maybe in race condition it throw error if user already been in contact and then breaks all
            # transaction
            if Contact.find_by(user_id: @current_user.id, contact_id: id).nil?
              new_contacts.push({:user_id => @current_user.id, :contact_id => id})
              #new_contacts_pn.push([@current_user.id, id]) # only for push notification , deleted for a while
            end
=begin
            # now, make sure that they are friends, if A add B, then A must be in B's contact too

            this part is commented.
            if Contact.find_by(user_id: id, contact_id: @current_user.id).nil?
              new_contacts.push({:user_id => id, :contact_id => @current_user.id})
            end
=end
          end

          # add new contact
          Contact.create(new_contacts)

          # send push new contact notification
          if !new_contacts_pn.empty?
            ContactPushNotificationJob.perform_later(new_contacts_pn)
          end

          # ok, now add all official user too
          role_official_user = Role.official
          if role_official_user.nil? == false
            user_role_ids = UserRole.where(role_id: role_official_user.id).pluck(:user_id).to_a
            official_account = User.where("id IN (?)", user_role_ids).where(application_id: @current_user.application_id)
            official_account = official_account.where.not(id: @current_user.id)
            official_account = official_account.pluck(:id)

            official_account = official_account - @current_user.contacts.pluck(:contact_id)

            official_account_to_be_added = Array.new
            official_account.each do |id|
              # check again, to prevent error
              if Contact.find_by(user_id: @current_user.id, contact_id: id).nil?
                official_account_to_be_added.push({:user_id => @current_user.id, :contact_id => id})
              end

              # auto dependent add, if A add B, then A in B's contact too
              if Contact.find_by(user_id: id, contact_id: @current_user.id).nil?
                official_account_to_be_added.push({:user_id => id, :contact_id => @current_user.id})
              end
            end

            # add official contact
            Contact.create(official_account_to_be_added)
          end

          # last, load all current contact of the user
          contact_id = @current_user.contacts.pluck(:contact_id)
          contacts = User.where("id IN (?)", contact_id)
          contacts = contacts.where.not(fullname: nil).where.not(fullname: "") # only show contact who has complete their profile (fullname not nil)
          contacts = contacts.order(fullname: :asc)

          contacts = contacts.as_json({:show_profile => true})

          favored_status = @current_user.contacts.pluck(:contact_id, :is_favored)
          contacts = contacts.map do |e|
            # is contact is always true since this will only load contact of this user
            e.merge!('is_favored' => favored_status.to_h[ e["id"] ], 'is_contact' => true )
          end
        end

        render json: {
          data: contacts,
          # phone_numbers_not_valid: phone_numbers_not_valid
					phone_numbers: phone_numbers
        }
      else
        raise InputError.new("Phone number must be an array.")
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
          message: e.message
        }
      }, status: 422 and return
    end
  end

end