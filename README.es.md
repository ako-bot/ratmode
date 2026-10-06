# 🐀 ratmode

> **Context-frugal navigation for coding agents.**  
> *Frugal, not reckless*: un ahorro que reduce el acierto no es ahorro, porque una respuesta barata pero equivocada cuesta más al corregirla.

[🇬🇧 Read in English](README.md)

`ratmode` le da a los agentes de código una forma disciplinada de navegar repositorios sin despilfarrar contexto:

> **`Localizar → Hipótesis → Leer → Verificar → Parar`**

> **Estado:** `v0.1, sin evaluar`. Las reglas salen de razonamiento y práctica, todavía no de mediciones. Ver [Estado y evaluación](#-estado-y-evaluación).

---

## ⚡ El problema

Ante una tarea, un agente autónomo tiende a explorar de más: abre archivos "por si acaso", recorre carpetas por curiosidad y acumula código irrelevante antes de tener una hipótesis.

Eso cuesta tokens y, además, suele diluir las instrucciones importantes con ruido, lo que empeora las decisiones posteriores e induce regresiones.

```text
Sin ratmode:
Tarea → ls → leer archivos "por si acaso" → buscar → leer más código → 💸 contexto quemado

Con ratmode:
Tarea → Localizar → Hipótesis → Lectura dirigida → Checkpoint → Solución → 🛑 Parar
```

---

## 🏛️ El sistema ratmode

`ratmode` no es simplemente un prompt; es una disciplina de navegación estructurada en 3 pilares:

```text
                    ratmode
                       │
        ┌──────────────┼──────────────┐
        ↓              ↓              ↓
  Token Firewall    RatIndex      Checkpoints
  (gasto cero)     (el camino)   (freno al caos)
```

* **Token Firewall:** Exige una hipótesis en 1 línea antes de abrir archivos; prohíbe explorar por curiosidad.
* **RatIndex:** Un mapa opcional, verificable y libre de pudrición para bases de código medianas y grandes.
* **Checkpoints:** Un cortafuegos estricto tras inspeccionar ~10 archivos o ~2.000 líneas sin aislar la causa.

---

## 📜 Las reglas

| Regla | En una línea |
| :--- | :--- |
| **Localizar antes de leer** | Busca por símbolo, endpoint o ID (`rg -n`, `grep -n`) antes de abrir archivos. La búsqueda global vale, con límites (`-w`, `-l`, `head`, excluir dependencias). |
| **Hipótesis previa** | Antes de explorar, di en una línea qué buscas y dónde crees que está. Si el usuario ya nombró el archivo, ve directo. |
| **Leer unidades completas** | Lee el símbolo entero con sus imports y tipos, o el archivo entero si tiene menos de ~300 líneas. Nada de ventanas fijas que cortan el contexto. |
| **Checkpoint de exploración** | Tras ~10 archivos o ~2.000 líneas sin aislar la causa, para y resume: qué descartaste, cuál es la hipótesis más fuerte y qué miras después. |
| **Cero invasión** | Nunca insertes marcas de navegación en el código fuente. Las balizas son identificadores que ya existen. |
| **El código manda** | Si un índice o documento discrepa del código, se corrige la referencia. |

*Los umbrales son orientativos: sirven como señal de alerta, no hace falta contar con exactitud. Y la regla de oro es que si una regla cuesta más de lo que ahorra en la tarea actual, no se aplica.*

---

## 🚀 Inicio rápido

### Opción A: pegar el bloque en las reglas de tu proyecto
Funciona en cualquier herramienta. Pégalo en `CLAUDE.md`, `AGENTS.md` o `GEMINI.md`. Para Cursor va en sus reglas de proyecto (`.cursor/rules` o `.cursorrules`) y para Aider en un archivo de convenciones (`CONVENTIONS.md`); comprueba la ruta exacta en la documentación de cada herramienta:

```markdown
## Navegación económica (ratmode)
- Localiza por símbolo, ruta de endpoint o ID (`rg -n` o `grep -n`) antes de abrir archivos; no explores por curiosidad.
- Cuando explores, declara en una línea qué buscas. No hace falta para archivos ya señalados.
- Lee el símbolo completo con sus imports y tipos (archivo entero si tiene <300 líneas), no ventanas fijas.
- La búsqueda global vale con límites: `-w`, `-l`, `head`, excluyendo `node_modules`, `dist` y `.git`.
- Tras ~10 archivos o ~2.000 líneas sin aislar la causa, para y resume: descartado, hipótesis actual, siguiente paso.
- Respuestas directas: diagnóstico técnico y diffs mínimos, sin relleno.
- Si existe INDICE.md, actualízalo al cambiar un símbolo listado. Si discrepa del código, manda el código.
```

### Opción B: instalarlo como skill
Si tu herramienta soporta skills, copia esta carpeta a su directorio de skills (en Claude Code, `.claude/skills/ratmode/` en el proyecto o `~/.claude/skills/ratmode/` para todos). El agente lo activará cuando le pidas *"ratmode"* o *"modo rata"*, ahorrar contexto o crear un índice.

---

## 🗺️ RatIndex: mapa verificable (opcional)

`RatIndex` es el componente de mapa de `ratmode`: un único `INDICE.md` que enruta al agente hacia los módulos correctos. Solo compensa en repos grandes; en uno pequeño, crearlo cuesta más de lo que ahorra.

| Tamaño (archivos de código, sin dependencias) | Estrategia |
| :--- | :--- |
| **< 50** | Sin índice. `ls` y búsqueda por símbolo. |
| **50 a 300** | Opcional: un `INDICE.md` en la raíz, 40 líneas como máximo. |
| **> 300, monorepo o dominios desacoplados** | `INDICE.md` raíz como enrutador y fichas `indices/NN_modulo.md` solo para módulos complejos, bajo demanda. |

*No lo crees si tu herramienta ya genera un mapa del repo (Aider lo hace) o si no lo quieres.*

### Formato

```markdown
### Módulo (`ruta/dir/`)
- `identificador`: responsabilidad en 3 a 5 palabras.
- ⚠️ Trampa técnica, dependencia oculta o regla crítica, en una línea.
```

Hay un ejemplo completo en [`examples/INDICE.md`](examples/INDICE.md). Escribe entre acentos graves **solo identificadores y rutas**, tal como existen en el código: los scripts de verificación los extraen de ahí y marcarían como faltante cualquier otra cosa, como un comando.

### Verificación

Un índice sin dueño se pudre, así que se comprueba: cada identificador y ruta listados debe existir físicamente en el repo.

```bash
# Linux, macOS, WSL, Git Bash
./scripts/verify_index.sh INDICE.md

# Windows (PowerShell)
.\scripts\verify_index.ps1 -IndexFile "INDICE.md"
```

Devuelven código de salida `0` si todo coincide, y `1` si algo se renombró o borró (y lo listan). Para mantenerlo vivo, la regla es sencilla: quien cambia, renombra o borra un símbolo listado actualiza su línea en el mismo cambio.

---

## 🛑 Cuándo no usarlo

- **Repos pequeños:** basta con las reglas de navegación; no hace falta índice.
- **Tareas triviales o con el archivo ya señalado:** no hace falta ceremonia, y las reglas lo contemplan.
- **Herramientas con mapa propio:** si ya tienes uno automático, un `INDICE.md` es redundante.

---

## 🔬 Estado y evaluación

`ratmode` está en `v0.1` y todavía no se ha medido. Lo que importa saber es si ahorra sin bajar el acierto. Si lo pruebas, cuenta tu caso en un issue con:
1. Una tarea real, ejecutada con y sin `ratmode`.
2. Tokens y llamadas a herramientas en cada caso.
3. Si la tarea quedó bien resuelta.

*Un resultado donde baje el acierto es tan útil como uno donde mejore.*

---

## 📁 Estructura

```text
ratmode/
├── README.md           # Guía principal en inglés
├── README.es.md        # Esta guía en español
├── SKILL.md            # Especificación completa
├── LICENSE             # MIT
├── scripts/
│   ├── verify_index.sh # Verificador Bash
│   └── verify_index.ps1# Verificador PowerShell
└── examples/
    ├── INDEX.md        # Ejemplo de RatIndex en inglés
    └── INDICE.md       # Ejemplo de RatIndex en español
```

---

## 📄 Licencia

MIT. Consulta [LICENSE](LICENSE).  
Autor: [ako-bot](https://github.com/ako-bot).
