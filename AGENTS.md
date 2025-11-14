# AGENTS.md — How to work on this Flutter repo

## Tooling
- Format Python with black (line length 88) and isort; enforce via pre-commit.
- Lint in CI must pass: ruff (all warnings) and mypy --strict.
- Run dart format . for Dart code before committing.
- Provide an .editorconfig so indentation and newlines stay consistent.
- Secrets and environment-specific values must be read from .env (never hard-code).
- Commit messages follow Conventional Commits (feat: ..., fix: ..., chore: ...).

## Testing instructions (Flutter)
- Write unit tests for all modified or newly added business logic (providers, services, utilities, domain logic).
- Write widget tests for all modified or newly added UI components, screens, navigation, and interactions.
- Both unit and widget tests are required for every code change.
- All tests must pass before completing an iteration or submitting code.
- If any test fails, fix the code or the test and re-run until the suite is green.
- Use flutter test --name "" to run a specific test during debugging.
- Do not deliver or finalize code without the corresponding tests and a successful test run.

## Entry point & app structure
- lib/main.dart only bootstraps the app: void main() => runApp(const App());
- Do not declare the top-level App widget or routing in main.dart.
- lib/src/app.dart contains the App widget, configures ThemeData, and references the router.

## Routing
- All routing logic lives in lib/src/router/app_router.dart.
- Do not put routing code in a generic core folder.

## Architecture overview & folder hygiene
- Use Clean Architecture with four layers.
- Use feature-first structure under lib/src/features/....
- Remove any empty or redundant folders.
- Keep controllers and screens directly under presentation/.
- Use absolute imports only—no ../.. paths.

## Folder structure
- lib/main.dart
- lib/src/app.dart
- lib/src/constants/app_constants.dart
- lib/src/data/ (shared or feature-agnostic repositories and datasources)
- lib/src/features/<feature>/domain/
- lib/src/features/<feature>/data/
- lib/src/features/<feature>/presentation/controllers/
- lib/src/features/<feature>/presentation/screens/
- lib/src/infra/ (global infra, e.g. Supabase provider)
- lib/src/router/ (app router)
- lib/src/theme/ (theme.dart, custom_theme.dart)
- firebase_options.dart
- supabase_options.dart

## Domain layer
- Location: features/<feature>/domain/.
- Purpose: core business logic, entities, and abstract interfaces.
- Contains entities, plain Dart models (suffix Model), use cases/interactors, and abstract repositories.
- Must not depend on outer layers (data, presentation, infra).

## Data layer
- Location: features/<feature>/data/ and shared src/data/.
- Purpose: concrete implementations of domain interfaces, data sources, and DTOs.
- Contains repository implementations (e.g. Supabase repositories) and DTO classes.
- DTOs must be hand-written (fromJson(), toJson(), copyWith()).
- No code generation (no freezed, no json_serializable, no @riverpod).
- Presentation layer must not call Supabase directly.

## Presentation layer
- Location: features/<feature>/presentation/.
- Purpose: UI widgets and state controllers.
- Contains controllers (in controllers/) and screens (in screens/).
- Screens consume controllers and use ref.listen for events.
- No business logic in widgets—delegate to use cases or controllers.

## Infrastructure layer
- Location: src/infra/.
- Purpose: shared clients/providers (e.g. supabaseProvider) and DI setup.
- Provides dependencies for other layers.

## State management
- Use Riverpod only for new code.
- All widgets extend HookConsumerWidget.
- Do not use plain StatelessWidget or ConsumerWidget for new code.
- Data fetch uses FutureProvider.
- Writes and updates use controller methods exposing AsyncValue.
- Do not use setState for domain logic.

## Imports
- No relative imports across layers.
- Use absolute package imports, for example:
- import 'package:app/src/features/auth/presentation/screens/login_screen.dart';

## UI & theming
- Use the shared theme from lib/src/theme/theme.dart.
- Put custom extensions and overrides in lib/src/theme/custom_theme.dart.
- Do not hard-code colors in widgets.
- UI must follow the shared design system.

## Naming conventions
- Folders and files use snake_case.
- Classes and enums use PascalCase.
- Functions and variables use camelCase.
- Data classes end with Model.
- Global constants use UPPER_SNAKE_CASE.

## Models & codegen
- Define all models manually.
- Suffix all data classes with Model.
- Remove part '*.g.dart' and any codegen-specific annotations.
- Do not use freezed, json_serializable, or @riverpod.

## Error handling & constants
- Use CustomException (from app_constants.dart) instead of throw Exception.
- Centralize all strings, API endpoints, and error messages in app_constants.dart.

## Design patterns
- Use repository pattern: UI → Controller → Use Case → Repository interface → Data source.
- Provide dependencies via Riverpod in infra/ or the feature’s presentation/controllers/.

## API & backend interaction
- All Supabase calls live in the data layer.
- Presentation layer never calls Supabase directly.
- CI should fail if UI-level Supabase calls are introduced.

## Tooling & automation (Dart/Flutter)
- Run dart format . before committing.
- Keep linting in analysis_options.yaml.
- Run tests on PRs and ensure no codegen artifacts are committed.

## Not allowed
- Direct API calls in UI.
- Business logic in widgets.
- print()—use dart:developer log(...) instead.
- Code generation (freezed, json_serializable, @riverpod).
- Relative imports.
- Mixed widget base types—use only HookConsumerWidget.

## How to build
- FLUTTER_PROJECT_DIR=<your/app/path> ./tools/codex_pubget.sh
- FLUTTER_PROJECT_DIR=<your/app/path> ./tools/codex_analyze.sh

## Tests
- FLUTTER_PROJECT_DIR=<your/app/path> ./tools/codex_test.sh

## Formatting
- FLUTTER_PROJECT_DIR=<your/app/path> ./tools/codex_format.sh

## PR policy
- Branch naming: feat/, fix/, chore/
- CI must pass analyzer + tests; request review from @maintainers.
