class AdminUser < ApplicationRecord
  has_secure_password

  belongs_to :wedding, inverse_of: :admin_user

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 6 }, if: -> { new_record? || password.present? }
  validates :wedding_id, presence: true, uniqueness: true
end
