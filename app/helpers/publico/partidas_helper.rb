module Publico::PartidasHelper
  def formatear_tiempo(segundos)
    [ segundos / 3600, segundos / 60 % 60, segundos % 60 ].map { |valor| valor.to_s.rjust(2, "0") }.join(":")
  end
end
