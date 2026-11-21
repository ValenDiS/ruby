import { Controller } from "@hotwired/stimulus"

const claveSesion = "rubipticos.chatbot.nodo"

export default class extends Controller {
  static targets = ["panel", "marco"]

  abrir(event) {
    event.preventDefault()
    const url = new URL(event.currentTarget.href)
    try {
      const nodo = sessionStorage.getItem(claveSesion)
      if (nodo) url.searchParams.set("nodo", nodo)
    } catch {
      // El navegador puede bloquear el almacenamiento. La guía sigue disponible.
    }
    this.panelTarget.showModal()
    this.marcoTarget.src = url.href
  }

  recordar() {
    const nodo = this.marcoTarget.querySelector("[data-chatbot-clave]")
    if (!nodo) return

    try {
      sessionStorage.setItem(claveSesion, nodo.dataset.chatbotClave)
    } catch {
      // La navegación dentro del panel funciona también sin almacenamiento.
    }
    if (this.panelTarget.open) nodo.querySelector("[data-chatbot-mensaje]").focus()
  }

  cerrar() {
    if (this.panelTarget.open) this.panelTarget.close()
  }
}
