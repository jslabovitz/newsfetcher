- Fix broken 'show' command:
  - Read 'result' in Subscription, to be able to show items info.

- Rename Result class to Feed?

- Move Profile#add_subscription and Profile.discover_feed into Subscription
  - as class methods?

- Detect JSON/XML/etc. based on content-type
  - if not application/json or application/xml, then look for leading <, {

- Use ETag instead of If-Last-Modified?
  - support latter if former is not available?
  - https://www.w3.org/Protocols/rfc2616/rfc2616-sec13.html#sec13.3.4

- Auto-discover on 'add'.

- Move import/export logic into add/show.
  - Add --format option: 'opml', 'json', 'details', 'summary' (default)

- Rework templating system:
  - use ERB instead of custom '%x' code -- bind to Item
  - replace #render with .erb file

- Change #make_email to #to_mail
  - Have subscription be authority for title, mail_from/to, etc.
  - Remove instance variables: @profile, @feed

- Change from Faraday to HTTParty?

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