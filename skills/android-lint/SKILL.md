---
name: android-lint
description: Run Spotless (ktlint) and Detekt linting for auto-anki; fix common suppression patterns
argument-hint: [check|fix]
---

auto-anki enforces Spotless (ktlint formatting) and Detekt (static analysis). Both must pass before committing.

Run from the worktree root (e.g. `master/`) where `gradlew.bat` lives:

```bash
cd /mnt/c/Users/enshi/local/github.com/trironkk/auto-anki/master
```

## Format (fix formatting issues)

```bash
android-gradle format
```

This runs `spotlessApply` on all subprojects. Run this first — it auto-fixes most issues.

## Check (verify everything passes)

```bash
android-gradle lint
```

This runs `spotlessCheck` + `detekt` on all subprojects. CI requires this to pass clean.

## Common Detekt suppressions

When Detekt flags something that can't be refactored away, suppress at the function or class level:

| Rule | Suppress annotation | Threshold |
|------|--------------------|-----------| 
| `TooGenericExceptionCaught` | `@Suppress("TooGenericExceptionCaught")` | Any `catch (e: Exception)` |
| `TooManyFunctions` | `@Suppress("TooManyFunctions")` | >11 functions in a class |
| `LongMethod` | `@Suppress("LongMethod")` | >60 lines |
| `NestedBlockDepth` | `@Suppress("NestedBlockDepth")` | >4 nesting levels |

Place `@Suppress` on the function or class, not the file:
```kotlin
@Suppress("TooGenericExceptionCaught")
private fun riskyOperation() {
    try { ... } catch (e: Exception) { ... }
}
```

## Workflow

1. `android-gradle format` — auto-fix formatting
2. `android-gradle lint` — check; if it fails, read Detekt output
3. Add `@Suppress` for legitimate violations, refactor if possible
4. `android-gradle lint` — confirm clean pass before committing
