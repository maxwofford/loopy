class ApiKey < ApplicationRecord
  belongs_to :user
  has_many :api_requests, dependent: :destroy

  validates :project, presence: true, format: { with: /\A[a-z0-9\-]+\z/i, message: "only allows letters, numbers, and dashes" }
  validates :key_hash, presence: true, uniqueness: true

  attr_accessor :raw_key

  SCOPES = %w[transactional:send].freeze

  def self.generate(user:, project:, scopes: [], log_request_body: true)
    secret = SecureRandom.hex(16)
    date = Date.current.strftime("%Y%m%d")
    username = user.email.split("@").first.gsub(/[^a-z0-9]/i, "").downcase

    raw_key = "auth!#{username}@#{project}_#{date}.#{secret}"

    api_key = create!(
      user: user,
      project: project,
      scopes: scopes & SCOPES,
      key_hash: Digest::SHA256.hexdigest(raw_key),
      log_request_body: log_request_body
    )
    api_key.raw_key = raw_key
    api_key
  end

  def self.find_by_raw_key(raw_key)
    find_by(key_hash: Digest::SHA256.hexdigest(raw_key))
  end

  def revoked?
    revoked_at.present?
  end

  def revoke!
    update!(revoked_at: Time.current)
  end

  def active?
    !revoked?
  end

  def has_scope?(scope)
    scopes.include?(scope)
  end

  def last_used_at
    api_requests.maximum(:created_at)
  end
end
