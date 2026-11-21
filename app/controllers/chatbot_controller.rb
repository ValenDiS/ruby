class ChatbotController < ApplicationController
  def show
    nodos = NodoChatbot.includes(opciones: :destino)
    @nodo = nodos.find_by(clave: params[:nodo].presence || "bienvenida")
    @nodo ||= nodos.find_by(clave: "bienvenida") if params[:nodo].present?
  end
end
