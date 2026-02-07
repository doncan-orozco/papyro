# Papyro Developer Documentation

Human-readable documentation and examples for the Papyro web publishing project.

## Quick Links
- [Project Overview](#project-overview)
- [Architecture](examples/architecture-overview.md)
- [Code Examples](examples/)

## Project Overview

**Papyro** is a web app for publishing articles about web development. The landing page is a personal portfolio/"about me" page, and the main content is long‑form writing inspired by **Writebook** by 37signals.

Core goals:
- **Publish-first** experience (reading and writing are the primary flows)
- **Clean Architecture** via Trailblazer
- **Rails 8** native stack (Solid Queue, Solid Cache, SQLite, Kamal 2)
- **Hotwire** frontend (Turbo + Stimulus)
- **Phlex** components with Tailwind CSS

## Technology Stack

### Backend
- Ruby 4.0.0+
- Rails 8.0+
- Trailblazer 2.1+ (Operations, Contracts)
- dry-validation, dry-monads
- SQLite with production optimizations
- Solid Queue, Solid Cache
- Action Cable

### Frontend
- Hotwire (Turbo + Stimulus)
- Phlex components
- Tailwind CSS
- Vanilla JavaScript (ES6+)

### Infrastructure
- Kamal 2 deployment
- SQLite production-ready
- No Redis required

## Design Principles

1. **Content-first**: reading and publishing are the primary workflows
2. **Clean Architecture**: complete separation of business logic from framework
3. **Explicit Flow**: no hidden magic or callbacks
4. **Performance**: fast pages, minimal JS, streaming where helpful
5. **Rails 8 Native**: embrace Rails 8 defaults

## Code Examples

Browse complete examples in the [examples/](examples/) directory:
- [Controllers](examples/controllers.md)
- [Operations](examples/operations.md)
- [Contracts](examples/contracts.md)
- [Models](examples/models.md)
- [Queries](examples/queries.md)
- [Services](examples/services.md)
- [Channels](examples/channels.md)
- [Phlex Views](examples/views.md) (page-level templates)
- [Phlex Components](examples/components.md) (reusable UI)
- [Design System](examples/design-system.md) (shadcn/ui → Phlex)
- [I18n](examples/i18n.md) (English + Spanish)
- [Stimulus Controllers](examples/stimulus.md)
- [Background Jobs](examples/jobs.md)
- [Tests](examples/tests.md)
- [Database](examples/database.md)
- [Deployment](examples/deployment.md)

## File Structure

```
papyro/
├── app/
│   ├── channels/           # WebSocket channels
│   ├── components/         # Phlex reusable UI components
│   ├── concepts/           # Trailblazer operations & contracts
│   ├── controllers/        # Skinny controllers
│   ├── javascript/
│   │   └── controllers/    # Stimulus controllers
│   ├── jobs/              # Solid Queue jobs
│   ├── models/            # ActiveRecord (persistence only)
│   ├── queries/           # Query objects
│   ├── services/          # Domain services
│   └── views/             # Phlex page-level templates
├── config/
│   ├── database.yml       # SQLite configuration
│   └── deploy.yml         # Kamal 2 configuration
├── storage/               # SQLite database files
└── test/                  # Minitest tests
```

## Quick Commands

```bash
# Development
bin/rails server
bin/rails console
bin/rails test

# Background Jobs (Solid Queue)
bin/rails solid_queue:start

# Deployment (Kamal 2)
kamal setup
kamal deploy
kamal app logs

# Database
bin/rails db:migrate
bin/rails db:seed

# Cache (Solid Cache)
bin/rails cache:clear
```

## Code Review Checklist

Before submitting code, ensure:
- [ ] Business logic is in Trailblazer Operations
- [ ] Validations use dry-validation contracts
- [ ] No callbacks in models
- [ ] Controllers only call Operations
- [ ] Pattern matching used for Result handling
- [ ] WebSocket broadcasts happen in Operations
- [ ] Phlex views are page-level templates (app/views/)
- [ ] Phlex components are reusable UI (app/components/)
- [ ] Phlex components receive all data as arguments
- [ ] Stimulus controllers are small and focused
- [ ] Tests cover both success and failure cases
- [ ] No hardcoded dependencies
- [ ] Using Solid Queue for background jobs
- [ ] Using Solid Cache for caching
- [ ] WebSocket channels are properly authorized
- [ ] Database indexes exist for common queries
