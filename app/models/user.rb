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
  validate :queda_un_admin_activo, on: :update

  scope :activos, -> { where(activo: true) }

  # Devuelve el usuario si las credenciales son correctas y está activo.
  def self.autenticar(credenciales)
    user = authenticate_by(credenciales)
    user if user&.activo?
  end

  private
    # Evita quedarse sin nadie que pueda administrar el backend.
    def queda_un_admin_activo
      era_admin_activo = rol_in_database == "admin" && activo_in_database
      return unless era_admin_activo && !(admin? && activo?)

      unless User.admin.activos.where.not(id: id).exists?
        errors.add(:base, "Tiene que quedar al menos un administrador activo.")
      end
    end
end
