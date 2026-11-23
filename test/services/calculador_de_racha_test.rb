require "test_helper"

class CalculadorDeRachaTest < ActiveSupport::TestCase
  setup do
    travel_to Time.zone.local(2026, 11, 20, 12, 0)
    @jugador = Jugador.create!(nombre: "Rachero")
    @numero = 0
  end

  # Cada partida necesita un críptico distinto: se juega una sola vez por jugador.
  def jugar(momento, rendida: false)
    @numero += 1
    criptico = cripticos(:mate).dup
    criptico.update!(id_fuente: "cr-racha-#{@numero}")

    fin = rendida ? { rendido_at: momento } : { resuelto_at: momento }
    @jugador.partidas.create!(criptico: criptico, iniciado_at: momento - 1.minute, **fin)
  end

  def racha
    CalculadorDeRacha.new(@jugador)
  end

  test "sin partidas la racha es 0" do
    assert_equal 0, racha.actual
    assert_equal 1, racha.contando_hoy
  end

  test "cuenta los días seguidos hasta hoy" do
    jugar(3.days.ago)
    jugar(2.days.ago)
    jugar(1.day.ago)
    jugar(1.hour.ago)

    assert_equal 4, racha.actual
    assert_equal 4, racha.contando_hoy
  end

  test "si hoy todavía no jugó, la racha de ayer sigue viva" do
    jugar(2.days.ago)
    jugar(1.day.ago)

    assert_equal 2, racha.actual
    assert_equal 3, racha.contando_hoy
  end

  test "un día sin jugar corta la racha" do
    jugar(4.days.ago)
    jugar(3.days.ago)
    jugar(1.day.ago)

    assert_equal 1, racha.actual
  end

  test "si ayer no jugó, la racha se perdió" do
    jugar(2.days.ago)

    assert_equal 0, racha.actual
    assert_equal 1, racha.contando_hoy
  end

  test "varias partidas el mismo día cuentan como un solo día" do
    jugar(3.hours.ago)
    jugar(2.hours.ago)

    assert_equal 1, racha.actual
  end

  test "rendirse también cuenta como día jugado" do
    jugar(1.day.ago, rendida: true)
    jugar(1.hour.ago)

    assert_equal 2, racha.actual
  end

  test "una partida sin terminar no cuenta" do
    criptico = cripticos(:mate).dup
    criptico.update!(id_fuente: "cr-abierta")
    @jugador.partidas.create!(criptico: criptico, iniciado_at: 1.hour.ago)

    assert_equal 0, racha.actual
  end

  test "usa la fecha de Argentina: las 23:30 cuentan para ese día" do
    jugar(Time.zone.local(2026, 11, 19, 23, 30))

    assert_equal 1, racha.actual
    assert_equal 2, racha.contando_hoy
  end

  test "sin partidas la mejor racha es 0" do
    assert_equal 0, racha.mejor
  end

  test "la mejor racha se guarda aunque se haya cortado" do
    jugar(10.days.ago)
    jugar(9.days.ago)
    jugar(8.days.ago)
    jugar(1.day.ago)
    jugar(1.hour.ago)

    assert_equal 2, racha.actual
    assert_equal 3, racha.mejor
  end

  test "si la racha actual es la más larga, también es la mejor" do
    jugar(6.days.ago)
    jugar(3.days.ago)
    jugar(2.days.ago)
    jugar(1.day.ago)

    assert_equal 3, racha.actual
    assert_equal 3, racha.mejor
  end
end
