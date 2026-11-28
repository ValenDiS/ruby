require "test_helper"

class CripticoTest < ActiveSupport::TestCase
  # Críptico válido de base; cada test cambia lo que necesita.
  def criptico(**cambios)
    Criptico.new({
      id_fuente: "test-1",
      enunciado: "Amor loco da una fruta del bosque",
      enumeracion: "(4)",
      respuesta: "MORA",
      definiciones: [ "una fruta del bosque" ],
      indicadores: [ "loco" ],
      material: [ "Amor" ],
      tipo: "anagrama",
      dificultad: "facil"
    }.merge(cambios))
  end

  test "un críptico bien armado es válido" do
    assert criptico.valid?, criptico.errors.full_messages.to_sentence
  end

  test "enunciado, respuesta, tipo y dificultad son obligatorios" do
    c = criptico(enunciado: nil, respuesta: nil, tipo: nil, dificultad: nil)
    assert c.invalid?
    %i[enunciado respuesta tipo dificultad].each { |campo| assert c.errors[campo].any?, "falta error en #{campo}" }
  end

  test "tipo y dificultad desconocidos son inválidos (sin levantar excepción)" do
    c = criptico(tipo: "palindromo", dificultad: "experto")
    assert c.invalid?
    assert c.errors[:tipo].any?
    assert c.errors[:dificultad].any?
  end

  test "la enumeración debe coincidir con el largo de la respuesta" do
    assert criptico(enumeracion: "(5)").invalid?
  end

  test "la enumeración ignora tildes y espacios" do
    c = criptico(enunciado: "Monja alborotada da un fiambre", respuesta: "JAMÓN", enumeracion: "(5)",
                 definiciones: [ "un fiambre" ], indicadores: [ "alborotada" ], material: [ "Monja" ])
    assert c.valid?, c.errors.full_messages.to_sentence
  end

  test "cada definición, indicador y material aparece en el enunciado" do
    assert criptico(definiciones: [ "una planta" ]).invalid?
    assert criptico(indicadores: [ "revuelto" ]).invalid?
    assert criptico(material: [ "Roma" ]).invalid?
  end

  test "la doble definición lleva exactamente 2 definiciones" do
    base = { enunciado: "Felino o herramienta para cambiar la rueda", respuesta: "GATO", enumeracion: "(4)",
             indicadores: [], material: [], tipo: "doble_definicion" }
    assert criptico(**base, definiciones: [ "Felino", "herramienta para cambiar la rueda" ]).valid?
    assert criptico(**base, definiciones: [ "Felino" ]).invalid?
  end

  test "oculta: la respuesta está dentro del material sin espacios" do
    base = { enunciado: "La cama tejida esconde la infusión argentina", enumeracion: "(4)",
             definiciones: [ "la infusión argentina" ], indicadores: [ "esconde" ], material: [ "cama tejida" ], tipo: "oculta" }
    assert criptico(**base, respuesta: "MATE").valid?
    assert criptico(**base, respuesta: "TACO").invalid?
  end

  test "anagrama: el material tiene las mismas letras que la respuesta" do
    assert criptico(respuesta: "ROMA").valid?
    assert criptico(respuesta: "MURO").invalid?
  end

  test "iniciales: las primeras letras del material forman la respuesta" do
    base = { enunciado: "Al principio, ocho sapos observan un animal peludo", enumeracion: "(3)",
             definiciones: [ "un animal peludo" ], indicadores: [ "Al principio" ], material: [ "ocho sapos observan" ],
             tipo: "iniciales" }
    assert criptico(**base, respuesta: "OSO").valid?
    assert criptico(**base, respuesta: "OSA").invalid?
  end

  test "finales: ignora conectores como «y»" do
    base = { enunciado: "Colas de álbum, casa y amor dan agua salada", enumeracion: "(3)",
             definiciones: [ "agua salada" ], indicadores: [ "Colas de" ], material: [ "álbum, casa y amor" ], tipo: "finales" }
    assert criptico(**base, respuesta: "MAR").valid?
    assert criptico(**base, respuesta: "MAL").invalid?
  end

  test "el id de la fuente es único también en la base" do
    duplicado = criptico(id_fuente: cripticos(:mate).id_fuente)
    assert duplicado.invalid?
    assert_raises(ActiveRecord::RecordNotUnique) { duplicado.save(validate: false) }
  end

  test "la base rechaza un tipo inválido aunque se saltee el modelo" do
    assert_raises(ActiveRecord::StatementInvalid) do
      fila = criptico(id_fuente: "x").attributes.except("id", "created_at", "updated_at")
      Criptico.insert_all!([ fila.merge("tipo" => "palindromo") ])
    end
  end

  test "jugables excluye desactivados por el admin y los que no vienen en la fuente" do
    cripticos(:mate).update!(en_fuente: false)
    assert_not_includes Criptico.jugables, cripticos(:mate)
    cripticos(:mate).update!(en_fuente: true, activo: false)
    assert_not_includes Criptico.jugables, cripticos(:mate)
  end

  test "elegibles del día son los marcados que se pueden jugar" do
    mate = cripticos(:mate)
    assert_includes Criptico.elegibles_del_dia, mate

    mate.update!(activo: false)
    assert_not_includes Criptico.elegibles_del_dia, mate
  end

  test "un críptico nuevo no es elegible para el día hasta que se marque" do
    assert_not Criptico.new.elegible_dia?
  end

  test "la base no acepta elegible_dia vacío" do
    assert_raises(ActiveRecord::NotNullViolation) do
      cripticos(:mate).update_column(:elegible_dia, nil)
    end
  end

  test "no se puede borrar un críptico con partidas" do
    criptico = cripticos(:mate)

    assert_not criptico.destroy
    assert Criptico.exists?(criptico.id)
  end
end
