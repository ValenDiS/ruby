require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "normaliza el email" do
    user = User.new(email_address: " DOWNCASED@EXAMPLE.COM ")
    assert_equal("downcased@example.com", user.email_address)
  end

  test "por defecto es editor de puntajes y activo" do
    user = User.new
    assert user.editor_puntajes?
    assert user.activo?
  end

  test "el email es obligatorio, válido y único" do
    assert_not User.new(email_address: "", password: "password").valid?
    assert_not User.new(email_address: "no-es-email", password: "password").valid?
    assert_not User.new(email_address: "ADMIN@example.com", password: "password").valid?
  end

  test "rechaza un rol inexistente" do
    user = User.new(email_address: "nuevo@example.com", password: "password", rol: "superusuario")
    assert_not user.valid?
    assert user.errors[:rol].any?
  end

  test "la base rechaza un rol inexistente" do
    assert_raises(ActiveRecord::StatementInvalid) do
      users(:admin).update_column(:rol, "superusuario")
    end
  end

  test "la contraseña tiene al menos 8 caracteres" do
    assert_not User.new(email_address: "nuevo@example.com", password: "corta").valid?
  end

  test "autenticar devuelve al usuario activo con credenciales correctas" do
    assert_equal users(:admin), User.autenticar(email_address: "admin@example.com", password: "password")
  end

  test "autenticar rechaza contraseña incorrecta y usuarios desactivados" do
    assert_nil User.autenticar(email_address: "admin@example.com", password: "otra")
    assert_nil User.autenticar(email_address: "inactivo@example.com", password: "password")
  end
end
