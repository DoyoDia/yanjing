# Repository Guidelines

## Project Structure & Module Organization
- `AppScope/` holds app-level metadata and shared resources (`app.json5`, `resources/`).
- `entry/` is the main module.
  - ArkTS UI and logic live in `entry/src/main/ets/` (e.g., `pages/`, `sensor/`, `video/`, `utils/`).
  - Native C++ code lives in `entry/src/main/cpp/` with headers in `include/` and NAPI glue in `napi_init.cpp`.
  - ETS type stubs for the native library are in `entry/src/main/cpp/types/libpanorama_renderer/`.
  - Resources are in `entry/src/main/resources/`.
- Tests are split into `entry/src/test/` (local unit tests) and `entry/src/ohosTest/` (device/ohos tests).
- Generated artifacts and dependencies land in `build/` and `oh_modules/` (do not edit manually).

## Build, Test, and Development Commands
These commands assume the HarmonyOS toolchain (DevEco Studio or hvigor CLI) is installed:
- `ohpm install` — install JS/ETS dependencies into `oh_modules/`.
- `hvigor clean` — remove build outputs.
- `hvigor assembleHap` — build the `entry` module HAP.
- `hvigor assembleApp` — build the full app package.
- `hvigor test` — run configured tests (unit/ohos depending on target setup).

## Coding Style & Naming Conventions
- ArkTS/ETS files use 2-space indentation; C++ uses 4-space indentation.
- File and component names are PascalCase (e.g., `EntryAbility.ets`, `PanoramaView.ets`).
- Variables and functions use camelCase; keep exported types/components in PascalCase.
- ETS linting is configured in `code-linter.json5`; C++ checks use `.clang-tidy` and `.clangd`.

## Testing Guidelines
- Test framework: Hypium (`@ohos/hypium`).
- Naming: `*.test.ets` (see `List.test.ets`, `LocalUnit.test.ets`).
- Place local unit tests in `entry/src/test/` and device/ohos tests in `entry/src/ohosTest/ets/test/`.

## Commit & Pull Request Guidelines
- No Git history is present in this workspace, so no repository-specific commit convention is available.
- Use concise, imperative commit subjects and include the affected area when helpful (e.g., `entry: add sensor smoothing`).
- PRs should describe the change, link relevant issues, and include screenshots or screen recordings for UI changes.

## Security & Configuration Tips
- Keep signing materials out of the repo; configure signing via `build-profile.json5` locally.
- Update app identity data only in `AppScope/app.json5`.

## Agent-Specific Instructions
- 和我沟通的时候用中文，你可以用英语思考。
