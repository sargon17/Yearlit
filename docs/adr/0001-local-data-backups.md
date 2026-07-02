# Local Data Backups

Yearlit will protect durable user-created data with automatic local **Data backups** stored as versioned JSON domain data in the app group, capped by a rolling retention window. Restoring a backup fully replaces current durable user-created data instead of merging records, because recovery must be predictable and merging Calendars, Check-ins, Mood Tracking entries, journal notes, and Habit Stacks would create unclear conflict rules and broken links.

## Considered Options

- Raw SwiftData store copies: rejected because they couple recovery to current persistence internals and schema behavior.
- Cloud-synced backups: rejected for v1 because the immediate problem is local data loss from risky app changes, and sync adds privacy and conflict complexity.
- Merge restore: rejected because it creates duplicate Calendars, stale Check-ins, and ambiguous Habit Stack links.

## Consequences

The restore UI can stay simple: users choose a dated backup from Settings and confirm a full replacement. The implementation must create a fresh backup before restore so a mistaken restore remains recoverable.
