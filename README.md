# NewsFetcher

NewsFetcher monitors RSS and Atom feeds and delivers new items as individual HTML emails. It tracks which feed items have already been delivered, so you only receive new content.


## Features

- Monitors multiple RSS/Atom feeds organized into subscriptions
- Delivers each new feed item as a separate HTML email with custom styling
- Tracks item history to avoid re-delivering the same content
- Supports multiple delivery methods (SMTP, Maildir, etc.)
- Configurable update intervals and age limits per subscription
- Multi-threaded updating for efficiency
- Feed discovery from web pages
- Per-subscription and global configuration


## Installation

```
gem install newsfetcher
```


## Quick Start

Initialize a profile with your email settings:

```
newsfetcher init --mail-from feeds@example.com --mail-to you@example.com
```

Discover a feed for a website:

```
newsfetcher discover https://example.com/
```

Add a feed subscription:

```
newsfetcher add https://example.com/feed.xml
```

Update all subscriptions and deliver new items:

```
newsfetcher update
```


## Usage

NewsFetcher organizes feeds into subscriptions stored in `~/.newsfetcher` by default. Each subscription has its own configuration and tracks which items have been delivered.

### Commands

- `init` — Initialize a new profile with email settings
- `add URI [PATH] [ID]` — Add a new feed subscription
- `update [IDs...]` — Update subscriptions and deliver new items
- `show [IDs...]` — Display subscription details
- `enable ID` — Enable a disabled subscription
- `disable ID` — Disable a subscription
- `remove ID` — Remove a subscription
- `reset ID` — Clear item history (next update will re-deliver all items)
- `edit ID` — Edit subscription configuration
- `dir` — Show the profile directory path
- `discover URI` — Find feeds in a web page
- `get URI` — Fetch and display a feed without saving
- `uniq` — Remove duplicate items from history
- `fix` — Fix subscription issues

### Configuration

Configuration lives in JSON files at the profile and subscription levels. Profile-level settings in `~/.newsfetcher/config.json` serve as defaults for all subscriptions.

Key configuration options:

- `mail_from`, `mail_to` — Email sender and recipient
- `mail_subject` — Subject line template (supports ERB)
- `delivery_method` — How to deliver mail (`:smtp`, `:maildir`, etc.)
- `delivery_params` — Parameters for the delivery method
- `update_interval` — Minimum time between updates (default: 1 hour)
- `max_age` — How long to track items (default: 30 days)
- `max_threads` — Number of concurrent subscription updates (default: 100)
- `disabled` — Whether to skip this subscription during updates
- `ignore_uris` — Array of regex patterns to ignore items
- `root_folder` — Prefix for maildir folders or mail subject
- `consolidate` — Use shorter folder names

Subscription-specific settings override profile defaults.

### Styling

Email messages use HTML with embedded CSS compiled from SCSS. The default stylesheet is included, but you can specify additional stylesheets:

```json
{
  "aux_stylesheets": ["~/.newsfetcher/custom.scss"]
}
```


## Automation

Run newsfetcher update periodically using cron, launchd, or your preferred scheduler to automatically check feeds and deliver new items.


## How It Works

NewsFetcher fetches each feed, parses it with Feedjira, and compares items against the subscription’s history. New items (not previously seen and within the configured age limit) are formatted as HTML emails and delivered using Ruby’s Mail gem.

Each subscription maintains two history files: one tracking delivered items, one tracking HTTP responses. These histories are automatically pruned based on the `max_age` setting.


## Requirements

Ruby 2.7 or later.


## License

MIT