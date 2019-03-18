class PasscodeMailer < ActionMailer::Base
  default from: ENV['SMTP_EMAIL_FROM']

  def send_passcode(user)
    @user = user
    # mg_client = Mailgun::Client.new ENV['MAILGUN_API_KEY']
    # message_params = {
    #   :from    => ENV['EMAIL_SENDER'],
    #   :to      => @user.email,
    #   :subject => "Your Passcode Login for #{@user.application.app_name}",
    #   :html    => passcode_template
    # }
    # mg_client.send_message ENV['MAILGUN_DOMAIN'], message_params

    mail(to: @user.email, subject: "Your Passcode Login for #{@user.application.app_name}")
  end

  private
    def passcode_template
      html = File.open("app/views/mailer/send_passcode.html.erb").read
      template = ERB.new(html)
      return template.result(binding)
    end

end
