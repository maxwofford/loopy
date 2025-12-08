if Rails.env.production?
  Rails.application.configure do
    config.action_mailer.delivery_method = :ses
  end
end
