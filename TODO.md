## Bugs (now)


## Improvements (soon)

- Read history only when needed.

- Move history functions to separate class?
  - load
  - save
  - prune
  - update
  - query

- Move info functions to separate class? (like Cocoa bundle?)
  - to_yaml
  - load
  - save
  - init

- Add 'prune' command to prune out old history (rewrite file).

- Add per-feed locks to avoid access by multiple processes/threads.

- Combine list/show/show-message commands.
  - Use flags to control what is shown.

- Merge main NewsFetcher module with Profile?


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

- Add dormancy period as default, configured per-profile, or per-feed.

- Release to rubygems.
  - Reset git history.
  - Write README documentation.
  - Bump version to 1.0.