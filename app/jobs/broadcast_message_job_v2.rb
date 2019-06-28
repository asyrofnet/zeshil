class BroadcastMessageJobV2 < ActiveJob::Base
    queue_as :default
  
    def perform(sender, target_user_emails, message,type,payload, broadcast_message_id)
      application = sender.application
  
      target_user_emails.each do |target_email|
        target_user = User.find_by(qiscus_email: target_email)
        if !target_user.nil?
          BroadcastUnitSenderJob.perform_later(sender, target_user, message,type,payload, broadcast_message_id)
        end
      end

    end
  
    
  end