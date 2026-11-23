class AddNombreNormalizadoToJugadores < ActiveRecord::Migration[8.1]
  def change
    add_column :jugadores, :nombre_normalizado, :string

    reversible do |direccion|
      direccion.up do
        jugadores = Class.new(ActiveRecord::Base) do
          self.table_name = "jugadores"
        end
        jugadores.reset_column_information
        jugadores.find_each do |jugador|
          jugador.update_columns(nombre_normalizado: jugador.nombre.unicode_normalize(:nfc).downcase)
        end
      end
    end

    change_column_null :jugadores, :nombre_normalizado, false
    add_index :jugadores, :nombre_normalizado, unique: true
  end
end
