namespace :cripticos do
  desc "Sincroniza el catálogo de crípticos desde la API. Uso: bin/rails cripticos:sincronizar[URL]"
  task :sincronizar, [ :url ] => :environment do |_tarea, args|
    url = args[:url].presence || SincronizadorDeCripticos.url_configurada
    puts "Sincronizando desde #{url}..."

    sincronizacion = SincronizadorDeCripticos.new(url: url).call
    puts sincronizacion.resumen
    sincronizacion.detalle_rechazados.each do |rechazo|
      puts "  Rechazado #{rechazo["id"]}: #{rechazo["motivo"]}"
    end
  end
end
