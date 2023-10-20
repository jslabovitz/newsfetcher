## BUGS


## ARCHITECTURAL IMPROVEMENTS

- save response status in history
  - will need history entry to be hash/object, not just timestamp

- convert history values from simple timestamp to History::Entry objects
  - call History#latest, then use entry.time instead of time, etc.

- rename 'path' to 'section'?

- add per-subscription locks to avoid access by multiple processes/threads


## FEATURES

- allow 'add' to take 'id' option to customize ID

- add 'remove' feature
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