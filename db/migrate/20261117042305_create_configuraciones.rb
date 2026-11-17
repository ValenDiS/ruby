class CreateConfiguraciones < ActiveRecord::Migration[8.1]
  def change
    create_table :configuraciones do |t|
      t.string :url_fuente, null: false, default: "https://ecorrons.github.io/cryptics-api/v1/cryptics.json"
      t.text :texto_bienvenida, null: false, default: "¡Bienvenido a Rubípticos! Elegí una dificultad y resolvé crípticos."

      t.timestamps
    end
    # La configuración es una sola fila.
    add_check_constraint :configuraciones, "id = 1", name: "configuraciones_fila_unica"
  end
end
