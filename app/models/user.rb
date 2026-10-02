class User < ApplicationRecord
  has_secure_password

  normalizes :email, with: ->(e) { e.strip.downcase }

  validates :email, presence: true,
                    uniqueness: { case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, presence: true, length: { minimum: 6 }, allow_nil: true
end
