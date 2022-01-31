- use TTY::Config

- detect duplicate items
  - item attributes are equal, *except* for ID

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