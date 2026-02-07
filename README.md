# Papyro

Papyro is a web publishing app for long‑form articles about web development.

## Goals
- Publish‑first writing experience
- Clean architecture (Trailblazer + dry‑rb)
- Rails 8 native stack (Solid Queue, Solid Cache, SQLite)
- Hotwire + Phlex for a fast, modern UI

## Tech Stack
- Ruby 4.0+
- Rails 8.0+
- Trailblazer 2.1, dry‑validation, dry‑monads
- Phlex + Tailwind CSS
- Hotwire (Turbo + Stimulus)
- SQLite (production‑ready)

## Project Structure
```
app/
	concepts/        # Operations + contracts
	components/      # Phlex UI components
	views/           # Phlex page templates
	controllers/     # Thin controllers
	models/          # ActiveRecord persistence only
	queries/         # Query objects
	services/        # Domain services
	channels/        # Action Cable
	javascript/      # Stimulus controllers
```

## Setup
```
bin/setup
```

## Development
```
bin/rails server
```

## Tests
```
bin/rails test
```

## Docs
See [docs/README.md](docs/README.md) for architecture, examples, and skills.
