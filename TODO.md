# TODO

*** do fixup:
  - change Subscription's disable' -> 'disabled'
  - change deliver_params -> delivery_params
  - change delivery_params.folder -> 'root_folder'

- make sure Mailer.send_mail is threadsafe
  - lock?
  - or create queue, and have #send_mail add to queue if in threading mode
    - separate thread to run Mailer#deliver?

- save response status & timestamp

- implement per-feed update interval
  - eg, run `update` every 15 minutes via cron, but only updating every 12 hours
  - add `update_interval` to BaseConfig

- implement retry on error in fetching/parsing
  - only show error if > retry count

- set Subscription ivars on init from @config, instead of referring to later

- re-implement Subscription#enable/disable


## BUGS


## IMPROVEMENTS

- rename 'path' to 'section'?

- add per-subscription locks to avoid access by multiple processes/threads

- move Config out to separate Simple::Config gem
  - use instance methods instead of hash
  - implement DSL to set fields, and do parsing

- split mail delivery out to own class?


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