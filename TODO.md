## BUGS


## IMPROVEMENTS

- save response status & timestamp

- rename 'path' to 'section'?

- add per-subscription locks to avoid access by multiple processes/threads

- define keys on config hash
  - avoid errors in using wrong/ignored keys
  - just use attr's, instead of hash?
  - pre-parse values, using defined types -- eg, array of URLs


## FEATURES

- implement per-feed update interval
  - eg, run `update` every 15 minutes via cron, but only updating every 12 hours
  - add `update_interval` to BaseConfig

- implement retry on error in fetching/parsing
  - only show error if > retry count

- allow unit suffixes on durations (s, m, h, d)

- allow 'add' to take 'id' option to customize ID

- add 'remove' feature to remove HTML element
  - specifies XPath expression to remove

- auto-discover on 'add'
  - or auto-add on discover?

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