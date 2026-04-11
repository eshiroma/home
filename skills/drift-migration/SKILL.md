---
name: drift-migration
description: Add a Drift ORM schema migration to utakata (AppDatabase in lib/database/database.dart)
argument-hint: [description of schema change]
---

utakata uses Drift for its database. Current schema version: check `int get schemaVersion` in
`lib/database/database.dart`. Tables: `Songs`, `LyricLineRows`.

Unlike Room, Drift uses code generation — schema changes require regenerating `database.g.dart`.

## Step 1: Modify the table class

Edit `lib/database/database.dart` to add/change a column in the relevant table class:

```dart
class Songs extends Table {
  // existing columns...
  TextColumn get myNewField => text().nullable()();        // nullable
  TextColumn get myList => text().withDefault(Constant('[]'))(); // non-null with default
  IntColumn get myFlag => integer().withDefault(Constant(0))();  // non-null int
}
```

## Step 2: Bump schemaVersion

```dart
@override
int get schemaVersion => N + 1;  // increment from current value
```

## Step 3: Add migration to MigrationStrategy

In the `onUpgrade` handler:

```dart
@override
MigrationStrategy get migration => MigrationStrategy(
  onUpgrade: (migrator, from, to) async {
    // existing migrations...
    if (from < N + 1) {
      await migrator.addColumn(songs, songs.myNewField);
      // For columns not supported by migrator.addColumn, use raw SQL:
      await customStatement(
        'ALTER TABLE songs ADD COLUMN my_field TEXT NULL',
      );
    }
  },
  beforeOpen: (details) async {
    // Add defensive check if the migration could silently fail:
    if (details.versionBefore != null && details.versionBefore! < N + 1) {
      try {
        await customStatement('ALTER TABLE songs ADD COLUMN my_field TEXT NULL');
      } catch (_) {} // Column already exists — expected on clean installs
    }
  },
);
```

## Step 4: Regenerate database.g.dart

```bash
cd /mnt/c/Users/enshi/local/github.com/eshiroma/utakata/main
/snap/bin/flutter pub run build_runner build --delete-conflicting-outputs
```

This regenerates `lib/database/database.g.dart`. Commit both `database.dart` and `database.g.dart`.

## Step 5: Build and verify

```bash
/snap/bin/flutter build apk --debug
```

A build failure here means the table class and generated code are out of sync — re-run build_runner.

## Step 6: Install and smoke test

Run `/android-build-install` for utakata, then `/logcat-crash` and watch for:
```
DriftWrappedException / SqliteException
```
This usually means the migration SQL column name doesn't match what Drift expects (snake_case).

## Common mistakes

- **Forgetting to run build_runner** — build succeeds if `database.g.dart` is stale, but runtime queries fail
- **camelCase vs snake_case**: Drift maps `myNewField` → `my_new_field` in SQL; use snake_case in `customStatement`
- **`migrator.addColumn` vs raw SQL**: prefer `migrator.addColumn` when available; fall back to `customStatement` for complex changes
- **No `beforeOpen` guard**: if a v→v+1 migration can silently fail (e.g. column already exists from a botched migration), add a defensive `try/catch` in `beforeOpen`
- **Committing only database.dart**: always commit `database.g.dart` alongside it
