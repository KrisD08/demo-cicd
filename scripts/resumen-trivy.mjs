// Resumen de Trivy para $GITHUB_STEP_SUMMARY (B5): vulnerabilidades por severidad.
// Uso: IMAGE_TAG=sha-... node scripts/resumen-trivy.mjs web=trivy.json >> "$GITHUB_STEP_SUMMARY"
import { existsSync, readFileSync } from "node:fs";

const SEVERIDADES = ["CRITICAL", "HIGH", "MEDIUM", "LOW", "UNKNOWN"];
const BLOQUEAN = new Set(["CRITICAL", "HIGH"]); // la regla del curso: CRITICAL,HIGH con corrección disponible
const etiqueta = process.env.IMAGE_TAG ? `:${process.env.IMAGE_TAG.slice(0, 11)}` : "";

const filas = process.argv.slice(2).map((arg) => {
  const [servicio, archivo] = arg.split("=");
  const imagen = `demo-cicd-${servicio}${etiqueta}`;
  if (!existsSync(archivo)) return `| ${imagen} | sin datos | | | | | |`;

  const crudo = readFileSync(archivo, "utf-8");
  const json = JSON.parse(crudo.charCodeAt(0) === 0xfeff ? crudo.slice(1) : crudo);
  const vulns = (json.Results ?? []).flatMap((x) => x.Vulnerabilities ?? []);
  const cuenta = (sev) => vulns.filter((v) => v.Severity === sev).length;
  const bloqueantes = vulns.filter((v) => BLOQUEAN.has(v.Severity) && v.FixedVersion).length;
  return `| ${imagen} | ${SEVERIDADES.map(cuenta).join(" | ")} | **${bloqueantes}** |`;
});

console.log(
  [
    "### Trivy: vulnerabilidades por severidad",
    "",
    "| Imagen | CRITICAL | HIGH | MEDIUM | LOW | UNKNOWN | CRITICAL/HIGH con corrección (bloquean) |",
    "|---|--:|--:|--:|--:|--:|--:|",
    ...filas,
    "",
    "_Las aceptadas en `.trivyignore` no se cuentan: Trivy las descarta antes de generar el reporte._",
  ].join("\n"),
);
