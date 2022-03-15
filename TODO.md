## BUGS


## IMPROVEMENTS

- rename 'dormant' term to 'expired'?

- add per-subscription locks to avoid access by multiple processes/threads

- expand testing
  - use Mail::TestMailer to test results


## FEATURES

- implement alternate subscription types
  - split Subscription into abstract base subclasses:
    - Feed -- RSS/Atom (Feedjira) feed
    - Twitter
      - configure with Twitter authentication info
      - test with test/twitter.json config (not in git repo)
    - Page -- page check
      - last-modified
      - element (XPath) change (by hash?)
    - other?

- re-add Our Town
  type: page
  uri: https://ourtownlive.com/ourtown/
  xpath: //*[@id="post-3"]/div/table[2]/tbody/tr[2]/td[1]

- auto-discover on 'add'

- allow update by section (eg, world)

- add 'config' command
  - '--root' specifies root config
  - use readline to show/edit values

- allow multiple feeds per subscription
  - add 'uris' attribute: hash of key/URI
  - save each feed with key
  - feeds are merged and treated as one
  - handles situations like TheGuardian's separate sections

- expand 'ignore' feature
  - each rule can match on any fields
    ignore:
      uri: /foo
      title: Bar

- add check/validate command
  - fetch HTML page for feed
  - verify that feed matches <link> element


## RELEASE

- release publicly
  - write README documentation
  - bump version to 1.0
  - reset git history
  - push to Github
  - release to Rubygems