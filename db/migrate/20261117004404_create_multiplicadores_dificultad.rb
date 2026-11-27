class CreateMultiplicadoresDificultad < ActiveRecord::Migration[8.1]
  def change
    create_table :multiplicadores_dificultad do |t|
      t.string :dificultad, null: false
      t.decimal :valor, precision: 3, scale: 2, null: false, default: 1

      t.timestamps
    end
    add_index :multiplicadores_dificultad, :dificultad, unique: true
    add_check_constraint :multiplicadores_dificultad, "dificultad IN ('facil', 'medio', 'avanzado')",
                         name: "multiplicadores_dificultad_dificultad_valida"
    add_check_constraint :multiplicadores_dificultad, "valor > 0 AND valor <= 5",
                         name: "multiplicadores_dificultad_valor_valido"
  end
end
