class CreateJugadores < ActiveRecord::Migration[8.1]
  def change
    create_table :jugadores do |t|
      # NOCASE: el nombre es único sin distinguir mayúsculas también en la base.
      t.string :nombre, null: false, collation: "NOCASE"
      t.string :token, null: false
      t.boolean :bloqueado, null: false, default: false

      t.timestamps
    end
    add_index :jugadores, :nombre, unique: true
    add_index :jugadores, :token, unique: true
  end
end
