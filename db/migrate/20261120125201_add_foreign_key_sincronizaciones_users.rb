class AddForeignKeySincronizacionesUsers < ActiveRecord::Migration[8.1]
  def change
    add_foreign_key :sincronizaciones, :users
  end
end
