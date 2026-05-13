---
name: restful-controllers
description: Guidelines and patterns for creating and refactoring Ruby on Rails controllers to follow strict RESTful web development standards. Use when Claude needs to review, refactor, or generate Rails controllers, evaluate routing structures, remove custom controller actions, or enforce strict CRUD operations.
---

# Rails RESTful Controllers

> **The canonical controller skill is [../controller/SKILL.md](../controller/SKILL.md).** Load that first for the full golden archetype. This file focuses specifically on the refactoring workflow and extraction patterns for converting non-RESTful controllers.

## Core Principles

1. **Strict CRUD Only**: Controllers must ideally be limited to the default seven actions: `index`, `show`, `new`, `create`, `edit`, `update`, `destroy`.
2. **Resources Over Actions**: The presence of custom actions (verbs like `publish` or adjectives like `featured`) strongly indicates a hidden resource that should be extracted into its own controller.
3. **Delegated Logic**: Controllers should remain skinny. Business logic should be delegated to Operations/Service objects, database queries to Query objects, and presentation logic to View objects.

## Controller Refactoring Workflow

When asked to review, write, or refactor a Rails controller:

1. Scan the controller for any actions outside the standard 7 CRUD operations.
2. Identify the underlying resource the custom action is manipulating.
3. Extract the action into a new controller or namespace.
4. Update `config/routes.rb` to ensure routes rely on `resources` rather than custom `get/post` mappings.
   - For nested resources, prefer `resources ... do; resource ...; end` over manual `scope` path rewriting.
   - Remember that nested resource routes often use parent-scoped param keys such as `article_slug` for `/articles/:slug/...` nested routes.

**For concrete extraction strategies and code examples**, read [refactoring-patterns.md](references/refactoring-patterns.md).
