## BUGS

- save individual tweets (not just threads) in history


## ARCHITECTURAL IMPROVEMENTS

- use Simple::History

- rename 'path' to 'section'?

- add per-subscription locks to avoid access by multiple processes/threads

- expand testing
  - use Mail::TestMailer to test results


## FEATURES

- allow individual tweet configuration by tweet ID
  - takes priority over main configuration

- ignore retweets with no text (default: off)

- ignore retweets of tweets that are >n days older than retweet (default: 1)

- ignore retweets of tweets by same user (default: true)

- ignore retweets of retweets, if <75 chars? (default: true)

- allow 'add' to take 'id' option to customize ID

- add 'remove' feature
  - specifies XPath expression to remove

- implement page subscription type
  - page check
  - last-modified
  - element (XPath) change (by hash?)

- auto-discover on 'add'

- allow update by section (eg, world)

- add 'config' command
  - '--root' specifies root config
  - use readline to show/edit values

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