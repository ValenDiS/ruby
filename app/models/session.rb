class Session < ApplicationRecord
  belongs_to :user

  scope :de_usuarios_activos, -> { joins(:user).merge(User.activos) }
end
