## Bugs (now)


## Improvements (soon)

- Rework message building/sending:
  - Remove Maildir support.
  - Implement msmtp delivery, if needed (new gem?).
  - Move message.rhtml into full message, not just HTML.
    - Include message header and stylesheet.
    - Read from .newsfetcher/message.erb if present, or use default.
    - hash items for:
      - dirname of subscription
      - basename of subscription
      - title of item
      - eg: johnl+News.%d@johnlabovitz.com => johnl+News.tech@johnlabovitz.com
  - Rework profile info.yaml file:
    - Delete: maildir, folder, coalesce, use_plus_addressing.

- Rename email_from/email_to to mail_from/mail_to.

- Rework history:
  - Use plain-text file instead of SDBM file.
  - Simply append ID/timestamp.
  - Read history only when needed.
  - Ignore entries older than certain date (~1 month, configurable).
  - Add 'prune' command to prune out old history (rewrite file).

- Implement Item class to deal with item-related data & logic.
  - Rename to Message?

- Use Logger instead of #warn/#puts.

- Add per-feed locks to avoid access by multiple processes/threads.


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