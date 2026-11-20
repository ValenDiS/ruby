class AddTablaReiniciadaAtToConfiguraciones < ActiveRecord::Migration[8.1]
  def change
    add_column :configuraciones, :tabla_reiniciada_at, :datetime
  end
end
