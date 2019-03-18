require 'apnotic'
require 'net-http2'

class ApnoticClient

  def self.send(alert, devicetoken, custom_payload, sound = nil)
    dev_path = Rails.root.join('shared', 'files', 'kiwari1.p12')
    prod_path = Rails.root.join('shared', 'files', 'kiwari2.p12')

    # create a persistent connection
    dev_connection = Apnotic::Connection.development(cert_path: dev_path, cert_pass: "")
    connection = Apnotic::Connection.new(cert_path: prod_path, cert_pass: "")

    notification       = Apnotic::Notification.new(devicetoken)
		notification.topic = "com.qiscus.kiwari"
    notification.custom_payload = custom_payload
    # if sound is nil, it's mean send silent push notification
    # no need to send alert and sound
    if sound != nil
      notification.alert = alert
      notification.sound = sound
    end

    connection.on(:error) do |exception|
      logger.error "Exception has been raised: #{exception}"
    end
    dev_connection.on(:error) do |exception|
      logger.error "Exception has been raised: #{exception}"
    end

    # prepare push
    dev_push = dev_connection.prepare_push(notification)
    push = connection.prepare_push(notification)

    # send
    dev_connection.push_async(dev_push)
    connection.push_async(push)

    # wait for all requests to be completed
    dev_connection.join
    connection.join

    # close the connection
    dev_connection.close
    connection.close

  end

end