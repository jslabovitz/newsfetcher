- Detect duplicate items
  - item attributes are equal, *except* for ID

- Auto-discover on 'add'?

- Move import/export logic into add/show.
  - Add --format option: 'opml', 'json', 'details', 'summary' (default)

- Replace #render with .erb file.

- Change from Faraday to HTTParty or HTTPClient?

- Avoid use of NewsFetcher module constants.
  - Set instance variables to defaults.

- Add per-feed locks to avoid access by multiple processes/threads.

- Expand testing:
  - Use Mail::TestMailer to test results.
  - Use Mail::FileDelivery to save files.

- Add check/validate command:
  - Fetch HTML page for feed.
  - Verify that feed matches <link> element.

- Add dormancy period as default, configured per-profile, or per-feed.

- Release:
  - Write README documentation.
  - Bump version to 1.0.
  - Reset git history.
  - Push to github.
  - Release to rubygems.