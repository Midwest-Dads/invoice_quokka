class ApplicationMailer < ActionMailer::Base
  default from: ENV["SMTP_EMAIL_ADDRESS"] || "from@example.com"
  layout "mailer"

  def notification_email
    @recipient = params[:recipient]
    @subject = params[:subject]
    @body = params[:body]

    mail(
      to: @recipient.email_address,
      subject: @subject
    )
  end
end
