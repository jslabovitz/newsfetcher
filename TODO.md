# TODO

## BUGS


## IMPROVEMENTS

- implement retry on error in fetching/parsing
  - eg, to handle timeouts, connection/read errors, bad data, etc.
  - only show error if > retry count

- re-implement Subscription#enable/disable

- add new Feed class to encapsulate title/items

- save last fetch response to file (Marshaled?)

- rename 'path' to 'section'?

- add per-subscription locks to avoid access by multiple processes/threads

- convert HTML document builder to ERB, for easier customization


## FEATURES

- allow unit suffixes on durations (s, m, h, d, w)

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