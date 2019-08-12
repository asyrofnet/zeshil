require 'test_helper'

class API::V1::Webhooks::BotCallbackTest< ActionDispatch::IntegrationTest
  setup { host! 'api.example.com' }

  test "webhook success" do
    sender = User.first
    target = User.second
    target.update(callback_url: "http://www.qiscus.com")
    
    CallbackBotPostcommentWorker.expects(:perform_later).once
    params = {
             "type": "post_comment",
             "payload": {
                 "from": {
                     "id": 1,
                     "email": sender.qiscus_email,
                     "name": "User1"
                 },
                 "room": {
                     "id": ChatRoom.first.qiscus_room_id,
                     "topic_id": 536,
                     "type": "group",
                     "name": "ini grup",
                     "participants": [
                         {
                             "id": 1,
                             "email":sender.qiscus_email,
                             "username": "User1",
                             "avatar_url": "http://avatar1.jpg"
                         },
                         {
                             "id": 2,
                             "email":target.qiscus_email,
                             "username": "User2",
                             "avatar_url": "http://avatar2.jpg"
                         }
                     ]
                 },
                 "message": {
                       "type": "text",
                       "payload": {},
                       "text": "isi pesan"
                   }
              }
         }

    QiscusSdk.expects(:new).never
    app_id = Application.first.app_id
    post "/api/v1/webhooks/bot-callback/"+app_id,
      params: params,
      headers: { }

    #assert_equal 200, response.status
    assert_equal Mime[:json], response.content_type

    response_data = JSON.parse(response.body)
    data_target = response_data["data"].first
    assert_equal target.callback_url, data_target["callback_url"]
  end

end