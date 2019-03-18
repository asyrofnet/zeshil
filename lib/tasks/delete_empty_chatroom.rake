namespace :qisme do

  task delete_empty_chatroom: :environment do
    DeleteEmptyChatroomJob.perform_now()
  end

end