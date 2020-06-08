- Move Profile#add_subscription and Profile.discover_feed into Subscription
  - as class methods?

- Detect JSON/XML/etc. based on content-type?

- Make new class to encompass both all feed data, including Item.
  - concepts: issue, edition, delivery, package
  - Subscription class manages this new class, but does not contain it

- Use ETag instead of If-Last-Modified?
  - support latter if former is not available?
  - for I-L-M, always send back *exact* string received from server in last request (don't parse/convert/etc.)
  - https://www.w3.org/Protocols/rfc2616/rfc2616-sec13.html#sec13.3.4

- Don't depend on Last-Modified date.
  - better to use heuristics to understand last update based on item dates

- Auto-discover on 'add'.

- Move import/export logic into add/show.
  - Add --format option: 'opml', 'json', 'details', 'summary' (default)

- After parsing feed, write current feed info to file in bundle.
  - title, link, updated, etc.
  - read this file when initializing subscription
  - (to avoid re-parsing feed just to get title, for example)
  - write items as well?
    - possibly integrate/replace history file?

- Rename 'history' file to 'seen'?
  - Fix data format to be lines of JSON?

- Keep track of errors.
  - If error occurs when fetching feed, append to 'errors' file.
    - Save date, error code, etc.
    - If number of errors exceeds maximum, log error; else ignore.
  - Otherwise delete 'errors' file on success.

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