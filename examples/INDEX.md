# Repository Navigation Map (Example)

> Generated with RatIndex (mapping module of ratmode v0.1). Code is the single source of truth.

### Core Authentication (`src/auth/`)
- `AuthService`: Orchestrator for login, session tokens, and refresh flows.
- `verifyJWT`: Inbound request validation middleware.
- ⚠️ Revoked sessions are stored in Redis with a 24h TTL.

### Billing & Checkout (`src/billing/`)
- `StripeProvider`: Official gateway adapter for subscription management.
- `createInvoice`: PDF invoice generation and fiscal stamping.
- ⚠️ `createInvoice` requires customer `taxId` or throws `BillingError`.

### Background Workers (`src/jobs/`)
- `QueueWorker`: BullMQ consumer for outbound emails and webhooks.
- ⚠️ Synchronous execution is disabled; heavy tasks must be queued.
