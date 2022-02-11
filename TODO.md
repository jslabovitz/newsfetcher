- figure out why 'rake test' is sending emails

- allow messages to be added via Maildir

- rename 'dormant' term to 'expired'?

- detect duplicate items
  - save hash of {title,author,date,content}
  - implement #duplicate?
  - re-implement history file -- per profile!
  - implement 'fix' to add existing entries to history

- improve 'ignore' feature
  - each rule can match on any fields
    ignore:
      uri: /foo
      title: Bar

- use TTY::Config

- remove Vox hard-coded filtering from render
  - integrate into subscription as 'modify'

- auto-discover on 'add'

- move import/export logic into add/show
  - add --format option: 'opml', 'json', 'details', 'summary' (default)

- replace #render with .erb file

- change from Faraday to HTTParty or HTTPClient or Excon?
    https://github.com/excon/excon

- avoid use of NewsFetcher module constants
  - set instance variables to defaults

- add per-feed locks to avoid access by multiple processes/threads

- expand testing
  - use Mail::TestMailer to test results
  - use Mail::FileDelivery to save files

- add check/validate command
  - fetch HTML page for feed
  - verify that feed matches <link> element

- add dormancy period as default, configured per-profile, or per-feed

- release publicly
  - write README documentation
  - bump version to 1.0
  - reset git history
  - push to Github
  - release to Rubygems