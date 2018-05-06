## Bugs (now)

- Make 'subscribe' work again.


## Improvements (soon)

- Do feed fetching/parsing in only one place.

- If --profile not specified, then run update/dormant/etc. on all profiles.

- Add command sub-class for commands that take list of subscriptions.
  - Parse subscription args.
  - Trap errors.
  - Show subscription path for all errors/statuses/logs.

- Implement Item class to deal with item-related data & logic.

- Use Logger instead of #warn/#puts.

- Add lock files (per profile? per feed?) to avoid multiple processes.


## Features (later)

- Import from OPML instead of NNW plist.
  - Existing gem for OPML?
  - Remove nokogiri-plist dependency.

- Allow stylesheets to be added/changed.

- Add check/validate command:
  - Fetch HTML page for feed.
  - Verify that feed matches <link> element.

- Add dormancy period as class default (constant), per-profile, and per-feed.

- Add option to use msmtp/sendmail instead of Maildir delivery.

- Release to rubygems.
  - Reset git history.
  - Write README documentation.
  - Bump version to 1.0.