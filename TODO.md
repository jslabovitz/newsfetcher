## Bugs (now)

- Feed discovery prompting is wonky.
  - Remove prompts; just print URL and let user copy/paste and try again.


## Improvements (soon)

- Expand testing:
    - Write actual test classes/methods.
    - Use Mail::TestMailer to test results.
    - Use Mail::FileDelivery to save files.

- Remove Maildir?
    - Simply use Mail's default delivery methods.

- Add command sub-class for commands that take list of subscriptions.
  - Parse subscription args.
  - Trap errors.
  - Show subscription path for all errors/statuses/logs.

- Implement Item class to deal with item-related data & logic.

- Use Logger instead of #warn/#puts.

- Add lock files (per profile? per feed?) to avoid multiple processes.


## Features (later)

- Allow stylesheets to be added/changed.

- Add check/validate command:
  - Fetch HTML page for feed.
  - Verify that feed matches <link> element.

- Add dormancy period as class default (constant), per-profile, and per-feed.

- Release to rubygems.
  - Reset git history.
  - Write README documentation.
  - Bump version to 1.0.