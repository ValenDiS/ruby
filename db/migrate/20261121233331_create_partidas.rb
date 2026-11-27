class CreatePartidas < ActiveRecord::Migration[8.1]
  def change
    create_table :partidas do |t|
      t.references :jugador, null: false, foreign_key: true
      t.references :criptico, null: false, foreign_key: true
      # iniciado_at queda vacío hasta que el jugador aprieta «Jugar».
      t.datetime :iniciado_at
      t.datetime :resuelto_at
      t.datetime :rendido_at
      t.integer :intentos, null: false, default: 0
      t.integer :pistas_usadas, null: false, default: 0
      # Se guardan al resolver, así un cambio de configuración no recalcula partidas viejas.
      t.integer :puntos

      t.timestamps
    end
    # Cada críptico se juega una sola vez por jugador.
    add_index :partidas, [ :jugador_id, :criptico_id ], unique: true

    add_check_constraint :partidas, "intentos BETWEEN 0 AND 5", name: "partidas_intentos_validos"
    add_check_constraint :partidas, "pistas_usadas BETWEEN 0 AND 4", name: "partidas_pistas_validas"
    add_check_constraint :partidas, "puntos IS NULL OR puntos >= 0", name: "partidas_puntos_no_negativos"
    add_check_constraint :partidas, "resuelto_at IS NULL OR rendido_at IS NULL", name: "partidas_resuelta_o_rendida"
    add_check_constraint :partidas, "(resuelto_at IS NULL AND rendido_at IS NULL) OR iniciado_at IS NOT NULL",
                         name: "partidas_terminada_tiene_inicio"
  end
end
