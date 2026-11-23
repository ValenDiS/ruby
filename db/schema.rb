# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_11_22_120000) do
  create_table "cripticos", force: :cascade do |t|
    t.boolean "activo", default: true, null: false
    t.string "autor"
    t.text "ayuda"
    t.datetime "created_at", null: false
    t.json "definiciones", default: [], null: false
    t.string "dificultad", null: false
    t.boolean "en_fuente", default: true, null: false
    t.string "enumeracion", null: false
    t.text "enunciado", null: false
    t.text "explicacion"
    t.string "id_fuente", null: false
    t.json "indicadores", default: [], null: false
    t.json "material", default: [], null: false
    t.string "origen"
    t.string "respuesta", null: false
    t.string "tipo", null: false
    t.datetime "updated_at", null: false
    t.index ["dificultad", "activo", "en_fuente"], name: "index_cripticos_on_dificultad_and_activo_and_en_fuente"
    t.index ["id_fuente"], name: "index_cripticos_on_id_fuente", unique: true
    t.index ["tipo"], name: "index_cripticos_on_tipo"
    t.check_constraint "dificultad IN ('facil', 'medio', 'avanzado')", name: "cripticos_dificultad_valida"
    t.check_constraint "length(trim(enunciado)) > 0", name: "cripticos_enunciado_no_vacio"
    t.check_constraint "length(trim(respuesta)) > 0", name: "cripticos_respuesta_no_vacia"
    t.check_constraint "tipo IN ('anagrama', 'oculta', 'charada', 'contenedor', 'inversion', 'supresion', 'homofono', 'doble_definicion', 'iniciales', 'finales', 'sustitucion', 'simbolos', 'combinada')", name: "cripticos_tipo_valido"
  end

  create_table "jugadores", force: :cascade do |t|
    t.string "nombre", null: false, collation: "NOCASE"
    t.string "token", null: false
    t.boolean "bloqueado", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "nombre_normalizado", null: false
    t.index ["nombre"], name: "index_jugadores_on_nombre", unique: true
    t.index ["nombre_normalizado"], name: "index_jugadores_on_nombre_normalizado", unique: true
    t.index ["token"], name: "index_jugadores_on_token", unique: true
  end

  create_table "nodos_chatbot", force: :cascade do |t|
    t.string "clave", null: false
    t.text "mensaje", null: false
    t.text "ejemplo"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["clave"], name: "index_nodos_chatbot_on_clave", unique: true
  end

  create_table "opciones_chatbot", force: :cascade do |t|
    t.integer "origen_id", null: false
    t.integer "destino_id", null: false
    t.string "texto", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["destino_id"], name: "index_opciones_chatbot_on_destino_id"
    t.index ["origen_id", "destino_id"], name: "index_opciones_chatbot_on_origen_id_and_destino_id", unique: true
  end

  create_table "sincronizaciones", force: :cascade do |t|
    t.integer "actualizados", default: 0, null: false
    t.datetime "created_at", null: false
    t.integer "creados", default: 0, null: false
    t.integer "desactivados", default: 0, null: false
    t.json "detalle_rechazados", default: [], null: false
    t.string "estado", null: false
    t.text "mensaje_error"
    t.integer "rechazados", default: 0, null: false
    t.datetime "updated_at", null: false
    t.string "url", null: false
    t.bigint "user_id"
    t.string "version"
    t.index ["estado", "created_at"], name: "index_sincronizaciones_on_estado_and_created_at"
    t.index ["user_id"], name: "index_sincronizaciones_on_user_id"
    t.check_constraint "creados >= 0 AND actualizados >= 0 AND desactivados >= 0 AND rechazados >= 0", name: "sincronizaciones_contadores_no_negativos"
    t.check_constraint "estado IN ('exitosa', 'sin_cambios', 'fallida')", name: "sincronizaciones_estado_valido"
  end

  add_foreign_key "opciones_chatbot", "nodos_chatbot", column: "destino_id"
  add_foreign_key "opciones_chatbot", "nodos_chatbot", column: "origen_id"
end
