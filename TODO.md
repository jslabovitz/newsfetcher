- Move HTML generation to ERB template?

- Allow stylesheets to be added/changed.

- Fix feeds:
  - Save feed title as @feed_title.
  - Unset @title if @feed_title == @title.

- Add check/validate command:
  - Fetch HTML page for feed.
  - Verify that feed matches <link> element.

- If --profile not specified, then run update/dormant/etc. on all profiles.

- Move command processing into separate classes.

- Add dormancy period as class default (constant), per-profile, and per-feed.

- Add option to use msmtp/sendmail instead of Maildir delivery.

- Try using Mail again to compose messages.

- Import from OPML instead of NNW plist.
  - Existing gem for OPML?
  - Remove nokogiri-plist dependency.

- Use Logger instead of #warn.

- Install on server as LaunchDaemon.

- Release to rubygems.
  - Reset git history.
  - Write README documentation.
  - Bump version to 1.0.