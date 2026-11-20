require "test_helper"

class SincronizacionTest < ActiveSupport::TestCase
  URL = "https://ejemplo.test/v1/cryptics.json".freeze

  # Sincronización válida de base; cada test cambia lo que necesita.
  def sincronizacion(**cambios)
    Sincronizacion.new({ url: URL, estado: "exitosa", version: "v1" }.merge(cambios))
  end

  def crear(**cambios)
    sincronizacion(**cambios).tap(&:save!)
  end

  # ---------- Validaciones ----------

  test "una sincronización bien armada es válida y arranca con contadores en 0" do
    sinc = sincronizacion

    assert sinc.valid?, sinc.errors.full_messages.to_sentence
    assert_equal [ 0, 0, 0, 0 ], [ sinc.creados, sinc.actualizados, sinc.desactivados, sinc.rechazados ]
    assert_equal [], sinc.detalle_rechazados
  end

  test "la URL es obligatoria" do
    assert sincronizacion(url: "").invalid?
  end

  test "un estado desconocido es inválido (sin levantar excepción)" do
    sinc = sincronizacion(estado: "a_medias")

    assert sinc.invalid?
    assert sinc.errors.key?(:estado)
  end

  test "los contadores son enteros no negativos" do
    assert sincronizacion(creados: -1).invalid?
    assert sincronizacion(rechazados: 1.5).invalid?
  end

  test "la base rechaza un estado inválido aunque se saltee el modelo" do
    assert_raises(ActiveRecord::StatementInvalid) do
      Sincronizacion.insert_all!([ { url: URL, estado: "a_medias" } ])
    end
  end

  test "la base rechaza contadores negativos aunque se saltee el modelo" do
    assert_raises(ActiveRecord::StatementInvalid) do
      Sincronizacion.insert_all!([ { url: URL, estado: "exitosa", creados: -1 } ])
    end
  end

  # ---------- resumen ----------

  test "resumen de una sincronización exitosa muestra la versión y los contadores" do
    sinc = sincronizacion(version: "2026-10-26.1", creados: 34, actualizados: 2, desactivados: 1, rechazados: 3)

    assert_equal "Versión 2026-10-26.1: 34 creados, 2 actualizados, 1 desactivados, 3 rechazados", sinc.resumen
  end

  test "resumen de una sincronización sin cambios" do
    assert_equal "Sin cambios (versión v1)", sincronizacion(estado: "sin_cambios").resumen
  end

  test "resumen de una sincronización fallida muestra el error" do
    sinc = sincronizacion(estado: "fallida", version: nil, mensaje_error: "La fuente respondió HTTP 404")

    assert_equal "Error: La fuente respondió HTTP 404", sinc.resumen
  end

  # ---------- ultima_version_exitosa ----------

  test "ultima_version_exitosa es nil si nunca hubo una exitosa" do
    assert_nil Sincronizacion.ultima_version_exitosa
  end

  test "ultima_version_exitosa toma la exitosa más reciente" do
    crear(version: "v1", created_at: 2.days.ago)
    crear(version: "v2", created_at: 1.day.ago)

    assert_equal "v2", Sincronizacion.ultima_version_exitosa
  end

  test "ultima_version_exitosa ignora las fallidas y las sin cambios" do
    crear(version: "v1", created_at: 3.days.ago)
    crear(estado: "sin_cambios", version: "v9", created_at: 2.days.ago)
    crear(estado: "fallida", version: "v8", mensaje_error: "error", created_at: 1.day.ago)

    assert_equal "v1", Sincronizacion.ultima_version_exitosa
  end

  # ---------- recientes ----------

  test "recientes ordena de la más nueva a la más vieja" do
    vieja = crear(created_at: 2.days.ago)
    nueva = crear(created_at: 1.hour.ago)

    assert_equal [ nueva, vieja ], Sincronizacion.recientes.to_a
  end
end
