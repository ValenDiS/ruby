class CreatePuntajesPorTipo < ActiveRecord::Migration[8.1]
  def change
    create_table :puntajes_por_tipo do |t|
      t.string :tipo, null: false
      t.integer :puntos, null: false, default: 100

      t.timestamps
    end
    add_index :puntajes_por_tipo, :tipo, unique: true
    add_check_constraint :puntajes_por_tipo, "puntos BETWEEN 10 AND 1000", name: "puntajes_por_tipo_puntos_validos"
    add_check_constraint :puntajes_por_tipo,
                         "tipo IN ('anagrama', 'oculta', 'charada', 'contenedor', 'inversion', 'supresion', 'homofono', " \
                         "'doble_definicion', 'iniciales', 'finales', 'sustitucion', 'simbolos', 'combinada')",
                         name: "puntajes_por_tipo_tipo_valido"
  end
end
