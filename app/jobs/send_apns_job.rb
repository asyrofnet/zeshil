class SendApnsJob < ActiveJob::Base
  queue_as :send_apns

  BASE_PATH = Rails.root.join('shared', 'files')

  def perform(application, alert, token, custom_payload, sound = nil)
    @apnotic_pool = set_apns_pool(application)
    response = dev_response = nil

    # send using prod cert
    @apnotic_pool.with do |connection|
      notification       = Apnotic::Notification.new(token)
      notification.topic = application.apns_cert_topic
      notification.custom_payload = custom_payload
      # if sound is nil, it's mean send silent push notification
      # no need to send alert and sound
      if sound != nil
        notification.alert = alert
        notification.sound = sound
      end

      response = connection.push(notification)
      raise "Timeout sending a push notification" unless response
    end

    # send using dev cert
    @dev_apnotic_pool = set_apns_pool_dev(application)
    @dev_apnotic_pool.with do |connection|
      notification       = Apnotic::Notification.new(token)
      notification.topic = application.apns_cert_topic
      notification.custom_payload = custom_payload
      # if sound is nil, it's mean send silent push notification
      # no need to send alert and sound
      if sound != nil
        notification.alert = alert
        notification.sound = sound
      end

      dev_response = connection.push(notification)
      raise "Timeout sending a push notification" unless dev_response
    end

    # Remove device token if not valid on dev and prod cert
    if (response.status == '410' && dev_response.status == '410') ||
      ((response.status == '400' && response.body['reason'] == 'BadDeviceToken') &&
      (dev_response.status == '400' && dev_response.body['reason'] == 'BadDeviceToken'))
        userdevicetoken = UserDeviceToken.find_by(devicetoken: token)
        userdevicetoken.destroy unless userdevicetoken.nil?
    end
  end

  private

  def set_apns_pool(application)
    @apnotic_pool = Apnotic::ConnectionPool.new({
      cert_path: BASE_PATH + application.apns_cert_prod,
      cert_pass: application.apns_cert_password
    }, size: 5) do |connection|
      connection.on(:error) { |exception| puts "Exception has been raised: #{exception}" }
    end
  end

  def set_apns_pool_dev(application)
    @dev_apnotic_pool = Apnotic::ConnectionPool.development({
      cert_path: BASE_PATH + application.apns_cert_dev,
      cert_pass: application.apns_cert_password
    }, size: 5) do |connection|
      connection.on(:error) { |exception| puts "Exception has been raised: #{exception}" }
    end
  end
end
