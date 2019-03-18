require 'net/http'

class MakeAllUsersAsContact < ActiveJob::Base
  queue_as :default

  def perform(application_id)

    application_users = User.where(application_id: application_id)
    contacts = nil
    ActiveRecord::Base.transaction do
      application_users.each do |user|
        current_user = User.find(user.id)
        users = User.where(application_id: application_id)
        users = users.where.not(id: current_user.id)
        users = users.pluck(:id)

        already_been_in_contacts = current_user.contacts.where("contacts.contact_id IN (?)", users).pluck(:contact_id)
        new_contacts_to_be_added = users - already_been_in_contacts

        new_contacts = Array.new
        new_contacts_to_be_added.each do |id|
          if Contact.find_by(user_id: current_user.id, contact_id: id).nil?
            new_contacts.push({:user_id => current_user.id, :contact_id => id})
          end

          if Contact.find_by(user_id: id, contact_id: current_user.id).nil?
            new_contacts.push({:user_id => id, :contact_id => current_user.id})
          end
        end
        # add new contact
        Contact.create(new_contacts)
      end
    end
  end

end