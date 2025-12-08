class User < ApplicationRecord
  has_many :api_keys, dependent: :destroy

  validates :hca_id, presence: true, uniqueness: true
  validates :email, presence: true

  ADMIN_HCA_IDS = %w[
    ident!ePlfv4
  ].freeze

  def admin?
    ADMIN_HCA_IDS.include?(hca_id)
  end
end
