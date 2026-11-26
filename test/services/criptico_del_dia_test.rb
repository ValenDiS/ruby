require "test_helper"

class CripticoDelDiaTest < ActiveSupport::TestCase
  setup do
    @elegibles = [ cripticos(:mate) ]
    2.times do |numero|
      criptico = cripticos(:mate).dup
      criptico.update!(id_fuente: "cr-dia-#{numero}")
      @elegibles << criptico
    end
  end

  test "la misma fecha da siempre el mismo críptico" do
    fecha = Date.new(2026, 11, 20)

    assert_equal CripticoDelDia.new(fecha).criptico, CripticoDelDia.new(fecha).criptico
  end

  test "días seguidos recorren todos los elegibles" do
    elegidos = (0..2).map { |dias| CripticoDelDia.new(Date.new(2026, 11, 20) + dias).criptico }

    assert_equal @elegibles.sort_by(&:id), elegidos.sort_by(&:id)
  end

  test "solo elige entre los elegibles que se pueden jugar" do
    @elegibles.drop(1).each { |criptico| criptico.update!(elegible_dia: false) }

    3.times do |dias|
      assert_equal cripticos(:mate), CripticoDelDia.new(Date.new(2026, 11, 20) + dias).criptico
    end
  end

  test "sin elegibles no hay críptico del día" do
    Criptico.update_all(elegible_dia: false)

    assert_nil CripticoDelDia.new.criptico
    assert_not CripticoDelDia.new.es?(cripticos(:mate))
  end

  test "es? dice si un críptico es el del día" do
    del_dia = CripticoDelDia.new(Date.new(2026, 11, 20))
    otro = (@elegibles - [ del_dia.criptico ]).first

    assert del_dia.es?(del_dia.criptico)
    assert_not del_dia.es?(otro)
  end
end
