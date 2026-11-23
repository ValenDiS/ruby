import test from "node:test"
import assert from "node:assert/strict"
import { readFile } from "node:fs/promises"
import { SourceTextModule, SyntheticModule, createContext } from "node:vm"

const fuente = await readFile(new URL("../../app/javascript/controllers/cronometro_controller.js", import.meta.url), "utf8")

async function crearReloj(segundos) {
  let ahora = 0
  let actualizar
  let cancelado = false
  const contexto = createContext({
    performance: { now: () => ahora },
    setInterval: callback => { actualizar = callback; return 1 },
    clearInterval: id => { assert.equal(id, 1); cancelado = true }
  })
  const stimulus = new SyntheticModule(["Controller"], function () {
    this.setExport("Controller", class {})
  }, { context: contexto })
  const modulo = new SourceTextModule(fuente, { context: contexto })
  await modulo.link(nombre => {
    assert.equal(nombre, "@hotwired/stimulus")
    return stimulus
  })
  await modulo.evaluate()
  const reloj = new modulo.namespace.default()
  reloj.transcurridoValue = segundos
  reloj.relojTarget = { textContent: "" }
  reloj.connect()
  return {
    reloj,
    avanzar(milisegundos) { ahora += milisegundos; actualizar() },
    cancelado: () => cancelado
  }
}

test("parte del tiempo del servidor y cuenta los segundos transcurridos", async () => {
  const { reloj, avanzar } = await crearReloj(125)
  assert.equal(reloj.relojTarget.textContent, "00:02:05")
  avanzar(2900)
  assert.equal(reloj.relojTarget.textContent, "00:02:07")
})

test("recupera el tiempo de una pestaña inactiva sin depender de la cantidad de ticks", async () => {
  const { reloj, avanzar } = await crearReloj(0)
  avanzar(3_661_000)
  assert.equal(reloj.relojTarget.textContent, "01:01:01")
})

test("permite duraciones superiores a un día", async () => {
  const { reloj } = await crearReloj(90_065)
  assert.equal(reloj.relojTarget.textContent, "25:01:05")
})

test("al desconectar limpia el intervalo y al volver toma una referencia nueva", async () => {
  const { reloj, avanzar, cancelado } = await crearReloj(30)
  avanzar(5000)
  reloj.disconnect()
  assert.equal(cancelado(), true)
  reloj.transcurridoValue = 120
  reloj.connect()
  assert.equal(reloj.relojTarget.textContent, "00:02:00")
  avanzar(1000)
  assert.equal(reloj.relojTarget.textContent, "00:02:01")
})
