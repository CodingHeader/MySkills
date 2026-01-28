---
name: project-structure-creator
description: Initialize, validate, and maintain project directory structure according to strict enterprise specifications (Feature-Sliced Design + Bulletproof Architecture). Use this skill when: (1) Initializing a new project or module, (2) Adding new features or components, (3) Refactoring directory structure, (4) Verifying compliance with project norms.
---

# Project Structure Creator

This skill enforces a strict, standardized project structure based on Feature-Sliced Design (FSD) and Bulletproof React principles. It ensures maintainability, scalability, and consistency across the codebase.

## Usage

When you need to create folders or files, ALWAYS refer to the rules below.
You can use the provided Python script `scripts/init_structure.py` to generate the initial skeleton or validate existing structure.

```bash
# To generate structure (requires python)
python skills/project-structure-creator/scripts/init_structure.py generate --template standard
```

## Core Rules (Strict Enforcement)

### 1. Naming Convention (名如其实)
- Directory names MUST be **lowercase**.
- Names must be descriptive (e.g., `order`, `user-profile`).
- **Singular** only, EXCEPT for `docs`, `pages`, `features`, `components` (top-level), `hooks`, `utils`, `types`.
- Example: `src/img` (not `imgs`), `src/test` (not `tests` unless root).

### 2. Max Depth ≤ 4 (深度 ≤ 4 层)
- Avoid deep nesting to prevent "import hell" and CI caching issues.
- Rule: Root to source file should not exceed 4 folder levels if possible.

### 3. Functional Cohesion (一个目录一件事)
- Organize by **Feature/Domain** (`features/order`), NOT by technical type (`controllers`, `services`).
- Example: `features/order/` contains `api/`, `components/`, `hooks/`, `types/` specific to orders.

### 4. Documentation (文档存放)
- `README.md` at Project Root.
- Other docs in `docs/`.
- Sub-project docs in `docs/<subproject>/`.
- Milestone docs in `docs/<topic>/` (e.g., `docs/login-plan.md`).

### 5. Physical Isolation (三方依赖与自有代码物理隔离)
- 3rd-party libs go to `dep/`, `vendor/`, or `node_modules/`.
- NEVER mix business code with vendor code.

### 6. Static Assets (静态资源单独目录存放)
- `src/img`, `src/file`, `src/movie`.

## Component Guidelines

### Single Responsibility (单一职责)
- Granularity ≤ 1 "Functional Verb".
- Example: `<Uploader>` and `<Previewer>` are separate, not `<UploadAndPreview>`.

### Naming (命名即文档)
- Format: `BusinessContext` + `Element`.
- Example: `UserProfileCard`, `NavigationBar`.
- NO ambiguous abbreviations (`InfoBox`, `NavBar`).

### No Side Effects (无全局副作用)
- No `window`, `document`, `localStorage` access directly.
- No hidden API calls.
- All configuration via **Props**.
- All interaction via **Events/Callbacks**.

### TypeScript Types (全导出)
- Every component folder MUST have `types.ts`.
- Export `Props`, `Enums`, `Interfaces`.

### Style Isolation (样式物理分离)
- Styles in `index.module.scss` or `styles/` (sibling).
- NO inline styles.
- NO `!important`.
- Use CSS Variables for theming.

### The "Trinity" (三件套)
- `index.ts` (Export everything)
- `README.md` (Props/Events table)
- `Demo` (Covering 100% API)

### Testing (100% 覆盖)
- Every Prop, Event, and Edge Case must be tested.

## Frontend Design (Folder Structure)

### Component Level
```text
Button/
├─ index.tsx
├─ index.module.scss
└─ types.ts
```

### Global Styles
```text
src/styles/
├─ global.scss      (Reset)
├─ variables.scss   (Theme vars)
├─ mixins.scss
└─ tailwind.css
```

### Feature Styles
- `features/xxx/index.module.scss` (Scoped overrides only).

### Component Logic
- `index.tsx` is entry.
- Complex logic -> `hooks.ts`, `utils.ts` (colocated).

### Router
```text
src/router/
├─ index.ts
└─ routes.ts
```

### API
```text
src/shared/api/
├─ order.ts
├─ user.ts
└─ index.ts
```

### Utils & Shared
```text
src/shared/
├─ utils/
├─ hooks/
├─ constants/
└─ types/
```

## Backend API Design Rules

1. **URL**: Lowercase + Kebab-case (`/user-orders`). Plural resources (`/users`).
2. **Methods**: `GET` (Read), `POST` (Create), `PUT` (Replace), `PATCH` (Update), `DELETE` (Remove).
3. **Status Codes**: `200` (OK), `201` (Created), `204` (No Content), `400` (Bad Request), `401` (Unauth), `403` (Forbidden), `404` (Not Found), `500` (Server Error).
4. **Versioning**: In URL (`/api/v1/`).
5. **Pagination**: Unified `page`/`pageSize`. Response: `{ items, total, page, pageSize }`.
6. **Errors**: Unified JSON `{ code, message, details, requestId }`.
7. **Security**: HTTPS + Bearer Token.
8. **Date**: ISO 8601 (`2025-01-27T14:30:00+08:00`).
9. **Idempotency**: `Idempotency-Key` header for POST/PUT.

## Configuration Rules

1. **Environment Specific**: `config.default.json`, `config.dev.json`, `config.prod.json`.
2. **Gitignore**: `.env`, `config.local.json`, `secret*.json`.
3. **Centralized**: All config in `config/` or `src/config/`. NO hardcoded strings.
4. **Static**: Load once at startup. No runtime hot-reloading.
5. **Validation**: Validate schema on startup. Crash if invalid.
6. **Secrets**: Audit logs for production config access.

## Behavior Guidelines

1. **No Ajax in Shared Components**: Keep them pure UI.
2. **Refactor Threshold**: Don't split components used < 3 times.
3. **Design First**: Agree on visual/interaction specs before coding.
4. **Decouple Shared**: Base components should not depend on each other if possible.
5. **Log Levels**: Use `info`/`error` correctly. No `debug` in prod.
6. **Docstrings**: Required for ALL functions/classes.
7. **Search Before Create**: Reuse existing utils/components.
