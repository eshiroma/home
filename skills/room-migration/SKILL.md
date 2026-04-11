---
name: room-migration
description: Checklist for adding a Room database migration to auto-anki (FlashcardDatabase)
argument-hint: [description of schema change]
---

Current DB version: check `version = N` in `app/src/main/java/com/example/autoanki/data/FlashcardDatabase.kt`.

## Step 1: Update the entity

Edit the relevant entity file (`Flashcard.kt`, `KnownWord.kt`, `ProcessedPhoto.kt`) to add/modify the column.

## Step 2: Write the migration object

In `FlashcardDatabase.kt`, add a new `Migration` object alongside existing ones:

```kotlin
private val MIGRATION_N_M = object : Migration(N, M) {
    override fun migrate(db: SupportSQLiteDatabase) {
        // Examples:
        db.execSQL("ALTER TABLE flashcards ADD COLUMN myField TEXT DEFAULT NULL")
        db.execSQL("ALTER TABLE flashcards ADD COLUMN myList TEXT NOT NULL DEFAULT '[]'")
        db.execSQL("CREATE TABLE new_table (...)")
    }
}
```

- Use `DEFAULT NULL` for nullable columns
- Use `DEFAULT '[]'` for non-null list columns (stored as JSON)
- Room does not support dropping columns via ALTER TABLE — use CREATE + copy + DROP if needed

## Step 3: Bump the version and register the migration

```kotlin
@Database(
    entities = [Flashcard::class, KnownWord::class, ProcessedPhoto::class],
    version = M,   // ← bump from N to M
    ...
)
```

And in `getDatabase`:
```kotlin
.addMigrations(MIGRATION_N_1_N, MIGRATION_N_M)  // add new migration
```

## Step 4: Build and verify

```bash
android-gradle assembleDebug
```

A build failure here usually means the entity and migration are out of sync — Room validates at compile time.

## Step 5: Install and smoke test

Run `/android-build-install`, then `/logcat-crash` and watch for:
```
IllegalStateException: Room cannot verify the data integrity
```
This means the migration SQL doesn't match the entity definition.

## Common mistakes

- **Forgetting to add the migration to `.addMigrations()`** — build succeeds, app crashes at runtime
- **Wrong default for non-null column** — use `DEFAULT ''` or `DEFAULT '[]'`, never omit default on existing rows
- **Bumping version without a migration** — causes crash unless `fallbackToDestructiveMigration()` is set (it's not, by design)
- **Schema export not configured** — `app/schemas/` dir doesn't exist in this project; Room schema validation is compile-time only
