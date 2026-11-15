class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy

  enum :rol, { admin: "admin", editor_puntajes: "editor_puntajes" }, validate: true

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :email_address, presence: true,
                            uniqueness: { case_sensitive: false },
                            format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 8 }, allow_nil: true
  validates :activo, inclusion: { in: [ true, false ] }

  scope :activos, -> { where(activo: true) }

  # Devuelve el usuario si las credenciales son correctas y está activo.
  def self.autenticar(credenciales)
    user = authenticate_by(credenciales)
    user if user&.activo?
  end
end
