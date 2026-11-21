class CreateRecorridoChatbot < ActiveRecord::Migration[8.1]
  def change
    create_table :nodos_chatbot do |t|
      t.string :clave, null: false, index: { unique: true }
      t.text :mensaje, null: false
      t.text :ejemplo
      t.timestamps
    end

    create_table :opciones_chatbot do |t|
      t.references :origen, null: false, foreign_key: { to_table: :nodos_chatbot }, index: false
      t.references :destino, null: false, foreign_key: { to_table: :nodos_chatbot }
      t.string :texto, null: false
      t.timestamps
      t.index [ :origen_id, :destino_id ], unique: true
    end
  end
end
