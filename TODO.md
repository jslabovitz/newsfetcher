- Rework templating system:
  - Use ERB instead of custom '%x' code.
    - Bind to Item.
  - Replace #render with .erb file.

- Change #make_email to #to_mail
  - Have subscription be authority for title, mail_from/to, etc.
  - Remove instance variables: @profile, @feed

- Change from Faraday to HTTParty?

- Avoid use of NewsFetcher module constants.
  - Set instance variables to defaults.

- Add 'prune' command to prune out old history.
  - Rewrite history file.

- Combine list/show/show-message commands.
  - Use flags to control what is shown.

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