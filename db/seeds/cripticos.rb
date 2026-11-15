# Carga inicial del catálogo de crípticos usando el mismo sincronizador que el admin.
# Se llama desde db/seeds.rb. La URL se puede cambiar con la variable CRIPTICOS_URL
# (por ejemplo, para usar un servidor local: http://localhost:4567/v1/cryptics.json).
puts "Sincronizando crípticos desde #{SincronizadorDeCripticos.url_configurada}..."
sincronizacion = SincronizadorDeCripticos.new.call
puts "  #{sincronizacion.resumen}"
sincronizacion.detalle_rechazados.each do |rechazo|
  puts "  Rechazado #{rechazo["id"]}: #{rechazo["motivo"]}"
end
