# Slack analyzer

**tl;dr: see [the result](tenures.md)**

Slack analyzer provides `slacktenure`, a script to fetch all users from a Slack
workspace and determine when they joined and potentially left the workspace.
This is used as a proxy for tenure with a company.

## Assumptions

- An employee is assumed to have joined the company at the date of their first
  public Slack message
- They are assumed to have left the company at the date of their last public
  Slack message
- If somebody joins and leaves without ever posting a public message, they
  don't show up in the final table
- Employee numbers are assigned in ascending order of the timestamp of the
  first message; this isn't necessarily the true order, especially not for the
  first few employees

## Environment

To run `slacktenure`, these two variables have to be set in the environment:

- `BOT_TOKEN`, set to a Slack API bot token with `users:read` scope
- `USER_TOKEN`, set to a Slack API user token with `search:read` scope

## Slack API calls

- Get all users: [`users.list`][1]
- Find first/last message of a user: [`search.messages`][2], queried with
  `from:<@USERID>`; this means that the result depends on the user who owns the
  `USER_TOKEN` and which private channels they have access to

After each API call, the script sleeps for 3 seconds to avoid hitting rate
limits.

[1]: <https://api.slack.com/methods/users.list>
[2]: <https://api.slack.com/methods/search.messages>

## Files

- [`tenures.tsv`](tenures.tsv) contains the tab-separated data for all users with Slack ID,
  name, title, status, and Unix timestamp of first and last message, where
  applicable; status can be one of
  - `active`: user is still active member of the workspace
  - `alum`: user is marked `deleted` and has a timestamp for their last message
  - `fresh`: user is active member of the workspace, but hasn't posted yet
  - `noshow`: user is marked `deleted` and never posted a message
- [`tenures.md`](tenures.md) is the Markdown-formatted view of the same data
  with no-shows removed, and human-readable datestamps, order by date of the
  first message
- The `.diff` files contain the diffs of the TSV data between two updates
