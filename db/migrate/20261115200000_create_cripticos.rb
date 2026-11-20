class CreateCripticos < ActiveRecord::Migration[8.1]
  TIPOS = %w[anagrama oculta charada contenedor inversion supresion homofono
             doble_definicion iniciales finales sustitucion simbolos combinada].freeze
  DIFICULTADES = %w[facil medio avanzado].freeze

  def change
    create_table :cripticos do |t|
      t.string :id_fuente, null: false   # "cr-013": id estable de la API
      t.text :enunciado, null: false
      t.string :enumeracion, null: false   # "(6)"
      t.string :respuesta, null: false   # en mayúsculas y con tildes, como viene
      t.json :definiciones, null: false, default: []
      t.json :indicadores, null: false, default: []
      t.json :material, null: false, default: []
      t.string :tipo, null: false
      t.string :dificultad, null: false
      t.text :ayuda
      t.text :explicacion
      t.string :autor
      t.string :origen                      # campo "fuente" del JSON
      # activo: lo maneja el admin (activar/desactivar a mano).
      # en_fuente: lo maneja el sincronizador (false si ya no viene en la API).
      t.boolean :activo, null: false, default: true
      t.boolean :en_fuente, null: false, default: true

      t.timestamps
    end

    add_index :cripticos, :id_fuente, unique: true
    add_index :cripticos, [ :dificultad, :activo, :en_fuente ]
    add_index :cripticos, :tipo

    add_check_constraint :cripticos, "tipo IN (#{TIPOS.map { |t| "'#{t}'" }.join(', ')})",
                         name: "cripticos_tipo_valido"
    add_check_constraint :cripticos, "dificultad IN (#{DIFICULTADES.map { |d| "'#{d}'" }.join(', ')})",
                         name: "cripticos_dificultad_valida"
    add_check_constraint :cripticos, "length(trim(enunciado)) > 0", name: "cripticos_enunciado_no_vacio"
    add_check_constraint :cripticos, "length(trim(respuesta)) > 0", name: "cripticos_respuesta_no_vacia"
  end
end
