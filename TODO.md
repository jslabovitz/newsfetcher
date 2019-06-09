## Bugs (now)


## Improvements (soon)

- Remove Maildir support.
  - Add 'mailer' parameter to profile:
      mailer: /usr/local/bin/msmtp -t ...
  - Rework profile info.yaml file:
    - Delete: maildir, folder, coalesce, use_plus_addressing.

- Create message/message.erb template.
  - Include message header and content.
  - Read from profile dir, if present.
  - Use ERB tags for current #send_item message keys.
  - Parse into message using Mail.read?

- Minify CSS.

- Rework history:
  - Use plain-text file instead of SDBM file.
  - Simply append ID/timestamp.
  - Read history only when needed.
  - Ignore entries older than certain date (~1 month, configurable).
  - Add 'prune' command to prune out old history (rewrite file).

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