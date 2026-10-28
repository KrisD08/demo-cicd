// Pruebas de integración: la aplicación completa levantada con Compose (o desplegada en un ambiente).
// Entran por web, como un usuario. APP_URL apunta a nginx, nunca a la API directo.
import { describe, it, expect } from "vitest";

const BASE = (process.env.APP_URL || "http://localhost:8080").replace(/\/$/, "");
const json = { "Content-Type": "application/json" };

describe(`la aplicación en ${BASE}`, () => {
  it("sirve la página", async () => {
    const r = await fetch(`${BASE}/`);
    expect(r.status).toBe(200);
    expect(await r.text()).toContain("<title>");
  });

  it("la API está sana y habla con la base de datos", async () => {
    const r = await fetch(`${BASE}/api/health`);
    expect(r.status).toBe(200);
    expect(await r.json()).toEqual({ status: "ok" });
  });

  it("rechaza un mensaje sin nombre", async () => {
    const r = await fetch(`${BASE}/api/mensajes`, { method: "POST", headers: json, body: JSON.stringify({ mensaje: "hola" }) });
    expect(r.status).toBe(400);
  });

  it("rechaza un mensaje de más de 280 caracteres", async () => {
    const r = await fetch(`${BASE}/api/mensajes`, { method: "POST", headers: json, body: JSON.stringify({ nombre: "Ana", mensaje: "x".repeat(281) }) });
    expect(r.status).toBe(400);
  });

  it("crea un mensaje y aparece primero en la lista", async () => {
    const texto = `Prueba de integración ${Date.now()}`;
    const creado = await fetch(`${BASE}/api/mensajes`, { method: "POST", headers: json, body: JSON.stringify({ nombre: "Pipeline", mensaje: texto }) });
    expect(creado.status).toBe(201);
    const lista = await (await fetch(`${BASE}/api/mensajes`)).json();
    expect(lista[0].mensaje).toBe(texto);
  });

  it("/api/estadisticas cuenta los mensajes y sube en uno al crear uno nuevo", async () => {
    const leer = async () => {
      const r = await fetch(`${BASE}/api/estadisticas`);
      expect(r.status).toBe(200);
      const { total } = await r.json();
      expect(Number.isInteger(total)).toBe(true);
      return total;
    };
    const antes = await leer();
    const creado = await fetch(`${BASE}/api/mensajes`, { method: "POST", headers: json, body: JSON.stringify({ nombre: "Pipeline", mensaje: `Estadísticas ${Date.now()}` }) });
    expect(creado.status).toBe(201);
    expect(await leer()).toBe(antes + 1);
  });

  it("las métricas de la API no se exponen a través de web", async () => {
    const r = await fetch(`${BASE}/metrics`);
    expect(r.status).toBe(404);
  });
});
