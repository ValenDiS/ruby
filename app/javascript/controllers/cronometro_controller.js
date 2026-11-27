import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["reloj"]
  static values = { transcurrido: Number }

  connect() {
    this.inicio = performance.now()
    this.actualizar()
    this.intervalo = setInterval(() => this.actualizar(), 1000)
  }

  disconnect() {
    clearInterval(this.intervalo)
  }

  actualizar() {
    const total = Math.max(0, Math.floor(this.transcurridoValue + (performance.now() - this.inicio) / 1000))
    const horas = Math.floor(total / 3600)
    const minutos = Math.floor(total / 60) % 60
    const segundos = total % 60
    this.relojTarget.textContent = [horas, minutos, segundos].map(valor => String(valor).padStart(2, "0")).join(":")
  }
}
