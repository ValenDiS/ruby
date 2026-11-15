class CreateSincronizaciones < ActiveRecord::Migration[8.1]
  def change
    create_table :sincronizaciones do |t|
      # Admin que la pidió. Es opcional porque la carga inicial (db:seed) la
      # corre el sistema. La FK a users se agrega cuando se mergee la issue 5.
      t.bigint :user_id
      t.string :url, null: false
      t.string :version                       # versión del catálogo recibido
      t.string :estado, null: false     # exitosa | sin_cambios | fallida
      t.integer :creados, null: false, default: 0
      t.integer :actualizados, null: false, default: 0
      t.integer :desactivados, null: false, default: 0
      t.integer :rechazados, null: false, default: 0
      t.json :detalle_rechazados, null: false, default: []  # [{ "id" => "cr-104", "motivo" => "..." }]
      t.text :mensaje_error

      t.timestamps  # created_at = fecha de la sincronización
    end

    add_index :sincronizaciones, :user_id
    add_index :sincronizaciones, [ :estado, :created_at ]

    add_check_constraint :sincronizaciones, "estado IN ('exitosa', 'sin_cambios', 'fallida')",
                         name: "sincronizaciones_estado_valido"
    add_check_constraint :sincronizaciones,
                         "creados >= 0 AND actualizados >= 0 AND desactivados >= 0 AND rechazados >= 0",
                         name: "sincronizaciones_contadores_no_negativos"
  end
end
