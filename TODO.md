## BUGS

- save individual tweets (not just threads) in history


## IMPROVEMENTS

- allow 'add' to take 'id' option to customize ID

- rename 'path' to 'section'?

- rename 'dormant' term to 'expired'?

- add per-subscription locks to avoid access by multiple processes/threads

- expand testing
  - use Mail::TestMailer to test results


## FEATURES

- implement page subscription type
  - page check
  - last-modified
  - element (XPath) change (by hash?)

- re-add Our Town
  type: page
  uri: https://ourtownlive.com/ourtown/

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

- write README documentation
- bump version to 1.0
- reset git history
- push to Github
- release to Rubygems
- release publicly