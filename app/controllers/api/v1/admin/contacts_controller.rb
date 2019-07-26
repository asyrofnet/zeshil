class Api::V1::Admin::ContactsController < ProtectedController
  before_action :authorize_admin

  # =begin
  # @apiVersion 1.0.0
  # @api {get} /api/v1/admin/contacts List of user contacts
  # @apiName AdminListofUserContacts
  # @apiGroup Admin - Contacts
  # @apiPermission Admin
  #
  # @apiParam {String} access_token Admin access token
  # @apiParam {Number} user_id User id.
  # @apiParam {Number} page Page number
	# @apiParam {Number} limit Limit
  # =end
  def index
    begin
      total_page = 0
      total = 0
      contacts = nil
      limit = params[:limit]
      page = params[:page]
      ActiveRecord::Base.transaction do
        if !params[:user_id].present? || params[:user_id] == ""
          raise InputError.new("User id must be present.")
        end

        user = User.find_by(id: params[:user_id], application_id: @current_user.application_id)
        raise InputError.new("User is not found.") if user.nil?

        # add all official user before loading contacts
        role_official_user = Role.official
        if role_official_user.nil? == false
          user_role_ids = UserRole.where(role_id: role_official_user.id).pluck(:user_id).to_a
          official_account = User.where("id IN (?)", user_role_ids).where(application_id: @current_user.application_id)
          official_account = official_account.where.not(id: user.id)
          official_account = official_account.pluck(:id)

          official_account = official_account - user.contacts.pluck(:contact_id)

          official_account_to_be_added = Array.new
          official_account.each do |id|
            official_account_to_be_added.push({:user_id => user.id, :contact_id => id})
          end

          # add official contact
          Contact.create(official_account_to_be_added)
        end


        # show contact except official account
        contact_id = user.contacts.where("contacts.contact_id NOT IN (select user_id from user_roles where role_id = ?)", Role.official.id).pluck(:contact_id)
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

        contacts = contacts.map(&:as_contact_json)

        contact_id = user.contacts.pluck(:contact_id)
        favored_status = user.contacts.pluck(:contact_id, :is_favored)
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
  # @apiVersion 1.0.0
  # @api {post} /api/v1/admin/contacts Add user contacts
  # @apiName AdminAddUserContacts
  # @apiGroup Admin - Contacts
  # @apiPermission Admin
  #
  # @apiParam {String} access_token User access token
  # @apiParam {Number} user_id User id.
  # @apiParam {Array} contact_id[] Array of user_id, e.g: `contact_id[]=1&contact_id[]=2`
  # =end
  def create
    begin
      if !params[:user_id].present? || params[:user_id] == ""
        raise InputError.new("User id must be present.")
      end
      user = User.find_by(id: params[:user_id], application_id: @current_user.application_id)
      raise InputError.new("User is not found.") if user.nil?

      candidate_contact_ids = params[:contact_id]
      if !candidate_contact_ids.is_a?(Array)
        raise InputError.new("Contact id must be an array of user id.")
      end
      candidate_contact_ids = candidate_contact_ids.collect{|i| i.to_i} # convert array of string to array of int

      contacts = users_not_found = already_been_in_contacts = nil
      ActiveRecord::Base.transaction do
        users = User.where("id IN (?)", candidate_contact_ids)
        users = users.where(application_id: @current_user.application.id) # only looking for user where has same application id
        user_ids = users.pluck(:id)
        users_not_found = candidate_contact_ids - user_ids

        already_been_in_contacts = user.contacts.where("contacts.contact_id IN (?)", user_ids).pluck(:contact_id)
        new_contacts_to_be_added = user_ids - already_been_in_contacts
        new_contacts_to_be_added = new_contacts_to_be_added.uniq
        new_contacts_to_be_added = new_contacts_to_be_added - [user.id] # exclude his/her self

        # now add to the contact
        new_contacts = Array.new
        new_contacts_pn = Array.new
        new_contacts_to_be_added.each do |id|
          # double check if user already been in contact.
          # maybe in race condition it throw error if user already been in contact and then breaks all
          # transaction
          if Contact.find_by(user_id: user.id, contact_id: id).nil?
            new_contacts.push({:user_id => user.id, :contact_id => id})
          end
=begin
          # now, make sure that they are friends, if A add B, then A must be in B's contact too
          if Contact.find_by(user_id: id, contact_id: user.id).nil?
            new_contacts.push({:user_id => id, :contact_id => user.id})
          end
=end          
        end

        # add new contact
        Contact.create(new_contacts)

        # last, load all current contact of the user
        contacts = User.where("id IN (?)", new_contacts_to_be_added)
        contacts = contacts.where.not(fullname: nil).where.not(fullname: "") # only show contact who has complete their profile (fullname not nil)
        contacts = contacts.order(fullname: :asc)

        contacts = contacts.as_json({:show_profile => true})

        favored_status = user.contacts.pluck(:contact_id, :is_favored)
        contacts = contacts.map do |e|
          # is contact is always true since this will only load contact of this user
          e.merge!('is_favored' => favored_status.to_h[ e["id"] ], 'is_contact' => true )
        end
      end

      # render user detail
      render json: {
        meta: {
          users_not_found: users_not_found,
          already_been_in_contacts: already_been_in_contacts
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
  # @apiVersion 1.0.0
  # @api {delete} /api/v1/admin/contacts Delete user contacts
  # @apiName AdminDeleteUserContacts
  # @apiGroup Admin - Contacts
  # @apiPermission Admin
  #
  # @apiParam {String} access_token User access token
  # @apiParam {Number} user_id User id.
  # @apiParam {Array} contact_id[] Array of user_id, e.g: `contact_id[]=1&contact_id[]=2`
  # =end
  def destroy_contacts
    begin
      if !params[:user_id].present? || params[:user_id] == ""
        raise InputError.new("User id must be present.")
      end
      user = User.find_by(id: params[:user_id], application_id: @current_user.application_id)
      raise InputError.new("User is not found.") if user.nil?

      candidate_contact_ids = params[:contact_id]
      if !candidate_contact_ids.is_a?(Array)
        raise InputError.new("Contact id must be an array of user id.")
      end
      candidate_contact_ids = candidate_contact_ids.collect{|i| i.to_i} # convert array of string to array of int

      contacts = users_not_found = not_in_contacts = nil
      ActiveRecord::Base.transaction do
        users = User.where("id IN (?)", candidate_contact_ids)
        users = users.where(application_id: @current_user.application.id) # only looking for user where has same application id
        user_ids = users.pluck(:id)
        users_not_found = candidate_contact_ids - user_ids

        contact_to_be_removed = user.contacts.where("contacts.contact_id IN (?)", user_ids).pluck(:contact_id)
        not_in_contacts = user_ids - contact_to_be_removed

        # remove contacts
        contacts = Contact.where(user_id: user.id)
        contacts = Contact.where("contact_id IN (?)", contact_to_be_removed)
        contacts.delete_all

        # last, load all current contact of the user
        contacts = User.where("id IN (?)", contact_to_be_removed)
        contacts = contacts.where.not(fullname: nil).where.not(fullname: "") # only show contact who has complete their profile (fullname not nil)
        contacts = contacts.order(fullname: :asc)

        contacts = contacts.as_json({:show_profile => true})

        favored_status = user.contacts.pluck(:contact_id, :is_favored)
        contacts = contacts.map do |e|
          # is contact is always true since this will only load contact of this user
          e.merge!('is_favored' => favored_status.to_h[ e["id"] ], 'is_contact' => true )
        end
      end

      # render user detail
      render json: {
        meta: {
          users_not_found: users_not_found,
          not_in_contacts: not_in_contacts
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

end
