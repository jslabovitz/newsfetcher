- Fix subscriptions:
  - Save feed title as @feed_title.
  - Unset @title if @feed_title == @title.

- Add check/validate command:
  - Fetch HTML page for feed.
  - Verify that feed matches <link> element.

- If --profile not specified, then run update/dormant/etc. on all profiles.

- Install on server as LaunchDaemon.

- Move command processing into separate classes.

- Add dormancy period as class default (constant), per-profile, and per-feed.

- HTML formatting:
  - Use external stylesheet (SASS), and embed compressed version.
  - Use classes for formatting headings/etc.
  - Tidy HTML?

- Add option to use msmtp/sendmail instead of Maildir delivery.

- Try using Mail again to compose messages.

- Import from OPML instead of NNW plist.
  - Existing gem for OPML?
  - Remove nokogiri-plist dependency.

- Use Logger instead of #warn.

- Release to rubygems.
  - Reset git history.
  - Write README documentation.
  - Bump version to 1.0.