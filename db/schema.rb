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

ActiveRecord::Schema[8.1].define(version: 2026_11_20_125201) do
  create_table "configuraciones", force: :cascade do |t|
    t.string "url_fuente", default: "https://ecorrons.github.io/cryptics-api/v1/cryptics.json", null: false
    t.text "texto_bienvenida", default: "¡Bienvenido a Rubípticos! Elegí una dificultad y resolvé crípticos.", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.check_constraint "id = 1", name: "configuraciones_fila_unica"
  end

  create_table "cripticos", force: :cascade do |t|
    t.string "id_fuente", null: false
    t.text "enunciado", null: false
    t.string "enumeracion", null: false
    t.string "respuesta", null: false
    t.json "definiciones", default: [], null: false
    t.json "indicadores", default: [], null: false
    t.json "material", default: [], null: false
    t.string "tipo", null: false
    t.string "dificultad", null: false
    t.text "ayuda"
    t.text "explicacion"
    t.string "autor"
    t.string "origen"
    t.boolean "activo", default: true, null: false
    t.boolean "en_fuente", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["dificultad", "activo", "en_fuente"], name: "index_cripticos_on_dificultad_and_activo_and_en_fuente"
    t.index ["id_fuente"], name: "index_cripticos_on_id_fuente", unique: true
    t.index ["tipo"], name: "index_cripticos_on_tipo"
    t.check_constraint "dificultad IN ('facil', 'medio', 'avanzado')", name: "cripticos_dificultad_valida"
    t.check_constraint "length(trim(enunciado)) > 0", name: "cripticos_enunciado_no_vacio"
    t.check_constraint "length(trim(respuesta)) > 0", name: "cripticos_respuesta_no_vacia"
    t.check_constraint "tipo IN ('anagrama', 'oculta', 'charada', 'contenedor', 'inversion', 'supresion', 'homofono', 'doble_definicion', 'iniciales', 'finales', 'sustitucion', 'simbolos', 'combinada')", name: "cripticos_tipo_valido"
  end

  create_table "multiplicadores_dificultad", force: :cascade do |t|
    t.string "dificultad", null: false
    t.decimal "valor", precision: 3, scale: 2, default: "1.0", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["dificultad"], name: "index_multiplicadores_dificultad_on_dificultad", unique: true
    t.check_constraint "dificultad IN ('facil', 'medio', 'avanzado')", name: "multiplicadores_dificultad_dificultad_valida"
    t.check_constraint "valor > 0 AND valor <= 5", name: "multiplicadores_dificultad_valor_valido"
  end

  create_table "puntajes_por_tipo", force: :cascade do |t|
    t.string "tipo", null: false
    t.integer "puntos", default: 100, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tipo"], name: "index_puntajes_por_tipo_on_tipo", unique: true
    t.check_constraint "puntos BETWEEN 10 AND 1000", name: "puntajes_por_tipo_puntos_validos"
    t.check_constraint "tipo IN ('anagrama', 'oculta', 'charada', 'contenedor', 'inversion', 'supresion', 'homofono', 'doble_definicion', 'iniciales', 'finales', 'sustitucion', 'simbolos', 'combinada')", name: "puntajes_por_tipo_tipo_valido"
  end

  create_table "sessions", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "sincronizaciones", force: :cascade do |t|
    t.bigint "user_id"
    t.string "url", null: false
    t.string "version"
    t.string "estado", null: false
    t.integer "creados", default: 0, null: false
    t.integer "actualizados", default: 0, null: false
    t.integer "desactivados", default: 0, null: false
    t.integer "rechazados", default: 0, null: false
    t.json "detalle_rechazados", default: [], null: false
    t.text "mensaje_error"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["estado", "created_at"], name: "index_sincronizaciones_on_estado_and_created_at"
    t.index ["user_id"], name: "index_sincronizaciones_on_user_id"
    t.check_constraint "creados >= 0 AND actualizados >= 0 AND desactivados >= 0 AND rechazados >= 0", name: "sincronizaciones_contadores_no_negativos"
    t.check_constraint "estado IN ('exitosa', 'sin_cambios', 'fallida')", name: "sincronizaciones_estado_valido"
  end

  create_table "users", force: :cascade do |t|
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.string "rol", default: "editor_puntajes", null: false
    t.boolean "activo", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
    t.check_constraint "rol IN ('admin', 'editor_puntajes')", name: "users_rol_valido"
  end

  add_foreign_key "sessions", "users"
  add_foreign_key "sincronizaciones", "users"
end
