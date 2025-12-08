class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("MAILER_FROM", "loopy@hackclub.com")
  layout "mailer"
end
