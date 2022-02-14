- convert YAML files to JSON

- ensure stylesheet is only added once
  - see test

- rework constants/config/parameters
  - use TTY::Config
  - avoid use of NewsFetcher module constants
  - set instance variables to defaults
  - fix log-level: not setting to config file?
  - add dormancy period as default, configured per-profile, or per-feed
  - rename 'dormant' term to 'expired'?

- add 'config' command
  - '--root' specifies root config
  - use readline to show/edit values

- add 'warn_on_move' attribute
  - if not set, treat moves as info

- allow multiple feeds per subscription
  - feeds are merged and treated as one
  - handles situations like TheGuardian's separate sections

- add per-feed locks to avoid access by multiple processes/threads

- expand testing
  - use Mail::TestMailer to test results
  - use Mail::FileDelivery to save files

- auto-discover on 'add'

- improve 'ignore' feature
  - each rule can match on any fields
    ignore:
      uri: /foo
      title: Bar

- move import/export logic into add/show
  - add --format option: 'opml', 'json', 'details', 'summary' (default)

- add check/validate command
  - fetch HTML page for feed
  - verify that feed matches <link> element

- release publicly
  - write README documentation
  - bump version to 1.0
  - reset git history
  - push to Github
  - release to Rubygems