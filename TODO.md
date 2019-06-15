## Bugs (now)


## Improvements (soon)

- Remove Maildir support.
  - Add 'mailer' parameter to profile:
      mailer: /usr/local/bin/msmtp -t ...
  - Rework profile info.yaml file:
    - Delete: maildir, folder, coalesce, use_plus_addressing.

- Rework history:
  - Use plain-text file instead of SDBM file.
  - Simply append ID/timestamp.
  - Read history only when needed.
  - Ignore entries older than certain date (~1 month, configurable).
  - Add 'prune' command to prune out old history (rewrite file).

- Use Logger instead of #warn/#puts.

- Add per-feed locks to avoid access by multiple processes/threads.


## Features (later)

- Look into minimizing styles:
    https://stackoverflow.com/questions/4829254/best-practices-for-styling-html-emails
    https://24ways.org/2009/rock-solid-html-emails
  - Use inline styles (attributes).
  - Don't link style sheets.
  - Do not use <style> tag (GMail strips that tag and contents).
  - Or punt and just let user deal with it?

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