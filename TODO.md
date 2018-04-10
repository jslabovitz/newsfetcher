- Rename project from 'feeder' -- conflicts with existing gem.

- Add lock files (per profile? per feed?) to avoid multiple processes.

- Split #update into #fetch and #process.
  - Add subcommands: update/fetch/process.

- Save feed XML file.

- Move history data into history.yaml (or history.db, if gdbm).

- Get last_modified from mtime of feed XML file.

- Move entry-specific code into Entry class.

- Copy Feedjira data into Feed/Entry objects.

- Move HTML generation to ERB template?

- Allow stylesheets to be added/changed.

- Fix feeds:
  - Save feed title as @feed_title.
  - Unset @title if @feed_title == @title.

- Add check/validate command:
  - Fetch HTML page for feed.
  - Verify that feed matches <link> element.

- If --profile not specified, then run update/dormant/etc. on all profiles.

- Add dormancy period as class default (constant), per-profile, and per-feed.

- Add option to use msmtp/sendmail instead of Maildir delivery.

- Import from OPML instead of NNW plist.
  - Existing gem for OPML?
  - Remove nokogiri-plist dependency.

- Use Logger instead of #warn/#puts.

- Release to rubygems.
  - Reset git history.
  - Write README documentation.
  - Bump version to 1.0.