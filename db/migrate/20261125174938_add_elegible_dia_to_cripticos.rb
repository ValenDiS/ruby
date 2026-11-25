class AddElegibleDiaToCripticos < ActiveRecord::Migration[8.1]
  def change
    # Marca los crípticos que pueden salir como críptico del día.
    # Los nuevos arrancan sin marcar: el admin decide cuáles entran.
    add_column :cripticos, :elegible_dia, :boolean, null: false, default: false
  end
end
