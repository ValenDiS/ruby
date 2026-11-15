# Datos iniciales del sistema. Es idempotente: se puede correr varias veces sin duplicar nada.
# Se cargan con bin/rails db:seed (o junto con la base con bin/rails db:setup).

# Primer administrador del backend (no hay registro público).
# Las credenciales se pueden cambiar con las variables de entorno ADMIN_EMAIL y ADMIN_PASSWORD.
admin_email = ENV.fetch("ADMIN_EMAIL", "admin@rubipticos.com")

User.find_or_create_by!(email_address: admin_email) do |user|
  user.password = ENV.fetch("ADMIN_PASSWORD", "admin1234")
  user.rol = :admin
end

puts "Admin: #{admin_email}"
