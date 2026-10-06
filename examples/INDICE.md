# Mapa de Navegación del Repositorio (Ejemplo)

> Generado con ratindex (módulo de mapa de ratmode v0.1). El código es la única verdad.

### Core Authentication (`src/auth/`)
- `AuthService`: Orquestador de login, refresh tokens y sesiones.
- `verifyJWT`: Middleware de validación en peticiones entrantes.
- ⚠️ Las sesiones revocadas se guardan en Redis con TTL de 24h.

### Billing & Checkout (`src/billing/`)
- `StripeProvider`: Adaptador oficial para pagos recurrentes.
- `createInvoice`: Generación y timbrado de facturas PDF.
- ⚠️ `createInvoice` requiere que el cliente tenga `taxId` o lanza `BillingError`.

### Background Workers (`src/jobs/`)
- `QueueWorker`: Consumidor de colas BullMQ para emails y webhooks.
- ⚠️ No procesa tareas síncronas; todo paso pesado debe encolarse.
