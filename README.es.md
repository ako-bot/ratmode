# 🐀 ratmode

> **Context-frugal navigation for coding agents.**  
> *Frugal, not reckless*: un ahorro que reduce la precisión no es ahorro, porque una respuesta barata pero equivocada cuesta más corregirla.

[🇬🇧 Read in English](README.md)

> Traducción informativa. La versión de referencia es el [README en inglés](README.md).

`ratmode` proporciona a los agentes de código una disciplina operativa para navegar repositorios sin desperdiciar contexto:

> **`Hypothesize → Locate → Read → Verify → Stop`**

> **Estado:** `v0.1, sin evaluar`. Estas reglas provienen del razonamiento técnico y la práctica diaria, todavía no de suites formales de benchmarks. Consulta [Estado y evaluación](#-estado-y-evaluación).

---

## ⚡ El problema

Al recibir una tarea, un agente autónomo tiende por defecto a sobre-explorar: abre archivos *"por si acaso"*, recorre árboles de directorios por curiosidad e ingiere miles de líneas irrelevantes antes de formular una hipótesis.

Esto desperdicia tokens y diluye las instrucciones críticas del sistema con ruido, degradando la calidad del razonamiento e induciendo regresiones.

```text
Sin ratmode:
Tarea → ls → leer archivos "por si acaso" → buscar → leer más archivos → 💸 contexto desperdiciado

Con ratmode:
Tarea → Hipótesis → Localizar → Lectura dirigida → Checkpoint → Solución → 🛑 Parar
```

---

## 🏛️ El sistema ratmode

`ratmode` no es simplemente un prompt; es una disciplina de navegación ligera basada en 3 pilares:

```text
                    ratmode
                       │
        ┌──────────────┼──────────────┐
        ↓              ↓              ↓
  Token Firewall    RatIndex      Checkpoints
 (limita el gasto) (mapa dirigido) (frena la deriva)
```

* **Token Firewall:** Exige una hipótesis provisional de 1 línea antes de leer código; prohíbe la navegación exploratoria a ciegas y combate el sesgo de confirmación.
* **RatIndex:** Un mapa de navegación opcional y estructuralmente verificado para bases de código extensas.
* **Checkpoints:** Un cortafuegos tras inspeccionar ~10 archivos o ~2.000 líneas sin aportar nueva evidencia.

> **Meta-regla:** Las reglas de `ratmode` son heurísticas de optimización, no cuotas dogmáticas. No se trata de minimizar la lectura por el simple hecho de minimizarla: se trata de minimizar aquella lectura que no aumente la probabilidad de resolver correctamente la tarea. Si alguna regla cuesta más contexto del que ahorra en la tarea actual, no la apliques.

---

## 📜 Las reglas

| Regla | En una línea |
| :--- | :--- |
| **Comprobar reglas del repo primero** | Revisa `CLAUDE.md`, `AGENTS.md` o `GEMINI.md` antes de explorar. Las directrices específicas del proyecto siempre mandan. |
| **El código es la única verdad** | Si un índice o documento discrepa del código fuente, actualiza la referencia. El código siempre gana. |
| **Hipótesis previa (Falsable)** | Declara en una línea qué buscas y dónde crees que está. Trátala como provisional: descártala o actualízala de inmediato si la evidencia la contradice. Salta este paso si los archivos ya fueron indicados. |
| **Localizar antes de leer** | Busca por símbolo, endpoint o ID (`rg -n`, `grep -n`) antes de abrir archivos. La búsqueda global está permitida con límites razonables (`-w`, `-l`, `head`, excluir dependencias). |
| **Mínima unidad semántica** | Lee la unidad semántica completa más pequeña suficiente para validar la hipótesis (función, método o hook con tipos/imports relevantes; archivo completo si <300 líneas). Sin ventanas ciegas de líneas fijas. |
| **Comprobar llamadores y referencias** | Antes de modificar firmas públicas o exportadas, inspecciona sus llamadores directos en todo el código usando referencias LSP/AST (o `grep -nw` dirigido). |
| **Medir sin abrir** | Usa `ls`, `find`, `wc -l` o `git ls-files` para inspeccionar volumen y estructura en vez de abrir contenidos de archivos únicamente para medir. |
| **Checkpoint de exploración** | Tras inspeccionar ~10 archivos o ~2.000 líneas sin producir **nueva evidencia**: para, resume las hipótesis descartadas, declara el indicio actual y planifica el siguiente paso. No confundir *sin solución aún* con *sin nueva evidencia*. |
| **Cero invasión en el código** | Nunca insertes marcas de navegación artificiales (`// [NAV]`) en el código fuente. Las balizas deben ser identificadores nativos preexistentes. |

---

## 🚀 Inicio rápido

### Opción A: Incorporar el bloque de reglas a tu proyecto
Funciona en cualquier herramienta con agentes. Añade este bloque a `CLAUDE.md`, `AGENTS.md` o `GEMINI.md`. Ten en cuenta que las rutas de configuración de las herramientas pueden cambiar (Cursor: `.cursor/rules` (o `.cursorrules`); Aider: `CONVENTIONS.md`. Comprueba la documentación de cada herramienta para la ruta exacta):

```markdown
## Frugal navigation (ratmode)
- Treat these as heuristics, not quotas: if a rule costs more context than it saves on the current task, skip it.
- Check repository rules first; never explore out of curiosity.
- Locate by symbol, endpoint, or ID (`rg -n` or `grep -n`) before opening files.
- When exploring, state in one line what you seek; discard the hypothesis as provisional if search contradicts it.
- Read smallest complete semantic units (functions/methods with imports and types; whole file if <300 lines), not arbitrary line windows.
- Check callers/references (LSP/AST or `grep -nw`) before changing public signatures.
- Global search is permitted with limits: `-w`, `-l`, `head`, excluding `node_modules`, `dist`, and `.git`.
- Checkpoint: After ~10 files or ~2,000 lines without new evidence, stop and summarize: ruled out, current lead, next step.
- Output direct diagnostics and minimal unified diffs; no conversational filler.
- If INDEX.md exists, keep listed symbols updated. If code and index disagree, code wins.
```

### Opción B: Instalar como Agent Skill
Si tu herramienta soporta el estándar de Agent Skills, copia esta carpeta en tu directorio de skills (p. ej., en Claude Code: `.claude/skills/ratmode/` a nivel de proyecto o `~/.claude/skills/ratmode/` de forma global). El agente lo activará automáticamente cuando se use alguno de estos disparadores: "rat mode", "ratmode", "save context", "reduce tokens", "create an index", "INDEX.md", o al añadir reglas de navegación a `CLAUDE.md`, `AGENTS.md` o `GEMINI.md`.

---

## 🗺️ RatIndex: Mapa estructuralmente verificado (Opcional)

`RatIndex` es el módulo opcional de mapeo de `ratmode`: una tabla de enrutamiento única en `INDEX.md` que orienta al agente hacia los módulos clave. La verificación es una **comprobación textual de existencia**: cada identificador o ruta listada aparece en algún lugar de la base de código. No confirma que el símbolo esté definido (una coincidencia en un comentario o string cuenta) ni que su descripción siga siendo correcta.

Solo compensa crearlo en repositorios grandes con un amplio espacio de búsqueda; en bases de código pequeñas, mantener un mapa cuesta más contexto del que ahorra.

| Tamaño (archivos de código fuente, sin dependencias ni dist) | Estrategia |
| :--- | :--- |
| **< 50 archivos** | Sin índice. Usa `ls` y búsqueda por símbolos. |
| **50 a 300 archivos** | Opcional: un único `INDEX.md` en la raíz, máximo 40 líneas. |
| **> 300 archivos, monorepos o dominios desacoplados** | `INDEX.md` en la raíz como router principal, con fichas `indices/NN_module.md` bajo demanda solo para dominios complejos. |

*No crees un índice si tu herramienta ya genera un mapa AST del repositorio (como Aider) o si prefieres no hacerlo.*

### Formato

```markdown
### Módulo (`ruta/dir/`)
- `identificador`: responsabilidad principal en 3 a 5 palabras.
- ⚠️ Gotcha, dependencia oculta o regla técnica crítica en 1 línea.
```

Una breve ilustración de 3 módulos está disponible en [`examples/INDEX.md`](examples/INDEX.md). Encierra entre acentos graves **únicamente identificadores y rutas exactos**, tal y como existen en el código fuente: los scripts de verificación extraen estos tokens directamente y marcarán como faltante cualquier texto plano o comando de terminal.

### Verificación

Un índice sin mantenimiento se degrada rápidamente. Ejecuta la verificación para confirmar que cada token listado existe en la base de código:

```bash
# Linux, macOS, WSL, Git Bash
./scripts/verify_index.sh INDEX.md
# O indicando una raíz de repositorio explícita:
./scripts/verify_index.sh INDEX.md path/to/repo

# Windows (PowerShell)
.\scripts\verify_index.ps1 -IndexFile "INDEX.md"
# O indicando una raíz de repositorio explícita:
.\scripts\verify_index.ps1 -IndexFile "INDEX.md" -RootPath "path\to\repo"
```

Los scripts terminan con código `0` si todos los símbolos coinciden, o `1` si algún símbolo fue renombrado o eliminado. Para mantener el mapa vivo: quien modifique o renombre un símbolo listado actualiza su línea en la misma confirmación (commit).

---

## 🛑 Cuándo no usarlo

- **Repositorios pequeños:** El listado de directorios y la búsqueda por símbolos bastan; un índice es pura sobrecarga.
- **Tareas triviales o archivos predeterminados:** No hace falta ceremonia; las reglas contemplan explícitamente la edición directa.
- **Herramientas con mapas AST nativos:** Si tu herramienta genera un mapa dinámico (p. ej., Aider), un archivo `INDEX.md` es redundante.

---

## 🔬 Estado y evaluación

`ratmode` se encuentra en versión `v0.1` y actualmente no cuenta con benchmarks formales. La pregunta clave es si reduce el consumo de tokens sin mermar la tasa de éxito de las tareas. Si experimentas con él, por favor comparte tus hallazgos en un issue:
1. Una tarea real ejecutada con y sin `ratmode`.
2. Total de tokens de entrada/salida y llamadas a herramientas en cada ejecución.
3. Si la tarea se resolvió correctamente.

*Un benchmark que demuestre menor precisión es tan valioso como uno que muestre ahorro.*

---

## 📁 Estructura del repositorio

```text
ratmode/
├── README.md           # Documentación en inglés (fuente de verdad)
├── README.es.md        # Documentación en español (este archivo)
├── SKILL.md            # Especificación completa de la skill para agentes
├── LICENSE             # Licencia MIT
├── scripts/
│   ├── verify_index.sh # Script de verificación en Bash
│   └── verify_index.ps1# Script de verificación optimizado en PowerShell
└── examples/
    └── INDEX.md        # Ejemplo de RatIndex (ilustración de 3 módulos)
```

---

## 📄 Licencia

MIT. Consulta [LICENSE](LICENSE).  
Autor: [ako-bot](https://github.com/ako-bot).
