class AdminUser < ApplicationRecord
  has_secure_password

  belongs_to :wedding, inverse_of: :admin_user

  generates_token_for :password_reset, expires_in: 2.hours do
    password_salt&.last(10)
  end

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 6 }, if: -> { new_record? || password.present? }
  validates :wedding_id, presence: true, uniqueness: true
end
