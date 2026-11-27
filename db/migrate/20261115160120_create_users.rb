class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :email_address, null: false
      t.string :password_digest, null: false
      t.string :rol, null: false, default: "editor_puntajes"
      t.boolean :activo, null: false, default: true

      t.timestamps
    end
    add_index :users, :email_address, unique: true
    add_check_constraint :users, "rol IN ('admin', 'editor_puntajes')", name: "users_rol_valido"
  end
end
