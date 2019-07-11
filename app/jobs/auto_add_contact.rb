require 'net/http'

class AutoAddContact < ActiveJob::Base
  queue_as :default

  def perform(user_ids, user_id)
    contacts = nil
    ActiveRecord::Base.transaction do
      # now looking for user where not in contact
      current_user = User.find(user_id)
      already_been_in_contacts = current_user.contacts.pluck(:contact_id)
      # contact to be added is only user where not in contact list
      new_contacts_to_be_added = user_ids - already_been_in_contacts

      # now add to the contact
      new_contacts = Array.new
      new_contacts_to_be_added.each do |id|
        # double check if user already been in contact.
        # maybe in race condition it throw error if user already been in contact and then breaks all
        # transaction
        if Contact.find_by(user_id: user_id, contact_id: id).nil?
          new_contacts.push({:user_id => user_id, :contact_id => id})
        end
=begin
        # now, make sure that they are friends, if A add B, then A must be in B's contact too
        if Contact.find_by(user_id: id, contact_id: user_id).nil?
          new_contacts.push({:user_id => id, :contact_id => user_id})
        end
=end        
      end

      # add new contact
      Contact.create(new_contacts)
    end
  end

end