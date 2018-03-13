- Fix subscriptions:
  - Unset @title if @feed_title == @title.

- Add check/validate command:
  - Fetch HTML page for feed.
  - Verify that feed matches <link> element.

- If --profile not specified, then run update/dormant/etc. on all profiles.

- Install on server as LaunchDaemon.

- Move command processing into separate classes.

- Add dormancy period as class default (constant), per-profile, and per-feed.

- HTML formatting:
  - Use external stylesheet (SASS), and embed compressed version.
  - Remove web bugs, etc.
    - Feedflare widgets:
      <div class="feedflare">
        <a href="http://feeds.macrumors.com/~ff/MacRumors-Front?a=Li0a2-XyvbY:AVVN9S8XlK8:yIl2AUoC8zA"><img src="http://feeds.feedburner.com/~ff/MacRumors-Front?d=yIl2AUoC8zA" border="0"></a>
        <a href="http://feeds.macrumors.com/~ff/MacRumors-Front?a=Li0a2-XyvbY:AVVN9S8XlK8:6W8y8wAjSf4"><img src="http://feeds.feedburner.com/~ff/MacRumors-Front?d=6W8y8wAjSf4" border="0"></a>
        <a href="http://feeds.macrumors.com/~ff/MacRumors-Front?a=Li0a2-XyvbY:AVVN9S8XlK8:qj6IDK7rITs"><img src="http://feeds.feedburner.com/~ff/MacRumors-Front?d=qj6IDK7rITs" border="0"></a>
      </div>
    - web bugs:
      <img src="http://feeds.feedburner.com/~r/MacRumors-Front/~4/Li0a2-XyvbY" height="1" width="1" alt="">
  - Fix iframe widths:
      <iframe width="640" height="360" frameborder="0" allowfullscreen="allowfullscreen" src="https://www.theatlantic.com/video/iframe/555359/"></iframe>
  - Use classes for formatting headings/etc.
  - Tidy HTML?

- Use Logger instead of #warn.

- Write README documentation.

- Release to rubygems (reset git history first).

- Add option to use msmtp/sendmail instead of Maildir delivery.

- Try using Mail again to compose messages.