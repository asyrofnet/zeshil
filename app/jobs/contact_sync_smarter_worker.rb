require 'net/http'

class ContactSyncSmarterWorker < ActiveJob::Base
  queue_as :default

  def perform(new_participant_ids, group_participant_ids, application_id)
    new_participant_ids.each  do |new_participant_id|

        contacts = nil
        ActiveRecord::Base.transaction do
          users = User.where("id IN (?)", group_participant_ids)
          users = users.where.not(fullname: nil).where.not(fullname: "") # only show contact who has complete their profile (fullname not nil)
          users = users.where(application_id: application_id) # only looking for user where has same application id
          users = users.where.not(id: new_participant_id) # exclude ownself to be added
          users = users.pluck(:id)

          # now looking for user where not in contact
          current_user = User.find(new_participant_id)
          already_been_in_contacts = current_user.contacts.where("contacts.contact_id IN (?)", users).pluck(:contact_id)
          # contact to be added is only user where not in contact list
          new_contacts_to_be_added = users - already_been_in_contacts

          # now add to the contact
          new_contacts = Array.new
          new_contacts_pn = Array.new
          new_contacts_to_be_added.each do |id|
            # double check if user already been in contact.
            # maybe in race condition it throw error if user already been in contact and then breaks all
            # transaction
            if Contact.find_by(user_id: current_user.id, contact_id: id).nil?
              new_contacts.push({:user_id => current_user.id, :contact_id => id})
              new_contacts_pn.push([current_user.id, id]) # only for push notification
            end
=begin
            # now, make sure that they are friends, if A add B, then A must be in B's contact too
            if Contact.find_by(user_id: id, contact_id: current_user.id).nil?
              new_contacts.push({:user_id => id, :contact_id => current_user.id})
            end
=end            
          end

          # add new contact
          Contact.create(new_contacts)

          # send new contact push notification
					# if !new_contacts_pn.empty?
					# 	ContactPushNotificationJob.perform_later(new_contacts_pn)
					# end
        end

    end
  end

end
