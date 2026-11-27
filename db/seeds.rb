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

# Configuración general (URL de la fuente y texto de bienvenida) con sus valores por defecto.
Configuracion.actual

# Valores iniciales del puntaje: 100 puntos por tipo y multiplicadores 1, 2 y 3.
Criptico::TIPOS.each do |tipo|
  PuntajePorTipo.find_or_create_by!(tipo: tipo) { |puntaje| puntaje.puntos = 100 }
end

{ "facil" => 1, "medio" => 2, "avanzado" => 3 }.each do |dificultad, valor|
  MultiplicadorDificultad.find_or_create_by!(dificultad: dificultad) { |multiplicador| multiplicador.valor = valor }
end

# Catálogo de crípticos: se trae de la API con el mismo sincronizador que usa el admin.
load Rails.root.join("db/seeds/cripticos.rb")
load Rails.root.join("db/seeds/chatbot.rb")
