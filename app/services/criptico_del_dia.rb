# Elige el críptico del día entre los elegibles (Criptico.elegibles_del_dia).
# Depende solo de la fecha: no hay azar ni datos del jugador, así que todos
# ven el mismo críptico ese día y al día siguiente pasa al próximo de la lista.
#
#   CripticoDelDia.new.criptico                   # => el de hoy
#   CripticoDelDia.new(Date.new(2026, 12, 1)).criptico
#   CripticoDelDia.new.es?(criptico)              # => true / false
class CripticoDelDia
  def initialize(fecha = Date.current)
    @fecha = fecha
  end

  # Se ordenan por id_fuente (el id de la API), que es el mismo en todas las bases.
  # El número de día juliano avanza de a 1 por día, así que se recorren todos en orden.
  def criptico
    return @criptico if defined?(@criptico)

    elegibles = Criptico.elegibles_del_dia.order(:id_fuente)
    cantidad = elegibles.count
    @criptico = cantidad.zero? ? nil : elegibles.offset(@fecha.jd % cantidad).first
  end

  def es?(otro)
    criptico.present? && criptico == otro
  end
end
