## Bugs (now)


## Improvements (soon)

- Rework history:
  - Use plain-text file instead of SDBM file.
  - Simply append ID/timestamp.
  - Read history only when needed.
  - Ignore entries older than certain date (~1 month, configurable).
  - Add 'prune' command to prune out old history (rewrite file).

- Add command sub-class for commands that take list of subscriptions.
  - Parse subscription args.
  - Trap errors.
  - Show subscription path for all errors/statuses/logs.

- Implement Item class to deal with item-related data & logic.

- Use Logger instead of #warn/#puts.

- Add lock files per-feed locks to avoid access by multiple processes/threads.


## Features (later)

- Expand testing:
    - Write actual test classes/methods.
    - Use Mail::TestMailer to test results.
    - Use Mail::FileDelivery to save files.

- Allow stylesheets to be added/changed.

- Add check/validate command:
  - Fetch HTML page for feed.
  - Verify that feed matches <link> element.

- Add dormancy period as class default (constant), per-profile, and per-feed.

- Release to rubygems.
  - Reset git history.
  - Write README documentation.
  - Bump version to 1.0.