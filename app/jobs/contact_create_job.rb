class ContactCreateJob < ActiveJob::Base
    queue_as :broadcast_starter
  
    def perform(current_user,already_been_in_contacts, new_contacts_to_be_added,phone_books)
      #update old contacts with new name
      already_been_in_contacts.each do |id|
        contact = Contact.find_by(user_id: current_user.id, contact_id: id)
        phone = User.find(id).phone_number
        if !contact.nil?
          if (contact.contact_name != phone_books[phone]) || (!contact.is_active)
            contact.update!(contact_name: phone_books[phone],is_active:true)
          end
        end
      end

      # now add to the contact
      new_contacts = Array.new
      new_contacts_to_be_added.each do |id|
        # double check if user already been in contact.
        # maybe in race condition it throw error if user already been in contact and then breaks all
        # transaction
        if Contact.find_by(user_id: current_user.id, contact_id: id).nil?
          phone = User.find(id).phone_number
          new_contacts.push({:user_id => current_user.id, :contact_id => id, :contact_name => phone_books[phone]})
        end

      end

      # add new contact
      Contact.create(new_contacts)
    end
  end