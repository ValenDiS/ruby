require "test_helper"

class AsignacionDeNombreTest < ActiveSupport::TestCase
  test "cambia el nombre conservando la identidad y los demás atributos" do
    jugador = jugadores(:pedrito)
    originales = jugador.attributes.except("nombre", "nombre_normalizado", "updated_at")

    assert_no_difference "Jugador.count" do
      resultado = AsignacionDeNombre.call(jugador: jugador, nombre: "Pedro")
      assert resultado.exitoso?
    end

    assert_equal "Pedro", jugador.reload.nombre
    assert_equal "pedro", jugador.nombre_normalizado
    assert_equal originales, jugador.attributes.except("nombre", "nombre_normalizado", "updated_at")
  end

  test "renombrar conserva las partidas y sus resultados" do
    jugador = jugadores(:pedrito)
    partida = partidas(:resuelta)
    originales = partida.attributes

    assert AsignacionDeNombre.call(jugador: jugador, nombre: "Pedro").exitoso?

    assert_equal originales, partida.reload.attributes
    assert_equal jugador.id, partida.jugador_id
    assert_includes jugador.partidas, partida
  end

  test "un nombre ocupado no modifica el registro y devuelve una sugerencia" do
    jugador = jugadores(:pedrito)
    originales = jugador.attributes
    resultado = AsignacionDeNombre.call(jugador: jugador, nombre: jugadores(:ofensivo).nombre)

    assert_not resultado.exitoso?
    assert_equal "NombreFeo_2", resultado.sugerencia
    assert_equal originales, jugador.reload.attributes
  end

  test "un nombre inválido no se considera exitoso aunque el jugador ya exista" do
    jugador = jugadores(:pedrito)
    resultado = AsignacionDeNombre.call(jugador: jugador, nombre: "Al")

    assert_not resultado.exitoso?
    assert resultado.jugador.errors[:nombre].any?
    assert_nil resultado.sugerencia
    assert_equal "Pedrito", jugador.reload.nombre
  end

  test "el jugador puede conservar su nombre o cambiar solamente las mayúsculas" do
    jugador = jugadores(:pedrito)

    assert AsignacionDeNombre.call(jugador: jugador, nombre: "Pedrito").exitoso?
    assert AsignacionDeNombre.call(jugador: jugador, nombre: "PEDRITO").exitoso?
    assert_equal "PEDRITO", jugador.reload.nombre
  end

  test "cambiar el nombre no quita un bloqueo administrativo" do
    jugador = jugadores(:ofensivo)

    assert AsignacionDeNombre.call(jugador: jugador, nombre: "NuevoNombre").exitoso?
    assert jugador.reload.bloqueado?
  end
end
