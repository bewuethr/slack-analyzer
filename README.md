# Slack analyzer

**tl;dr: see [all tenures](outputs/tenures.md),
[current employees](outputs/tenurescurrent.md), and
[latest diff](diffs/update-YYYY-MM-DD-HH.diff)**

![Employee turnover over time](outputs/turnover.svg)

Slack analyzer provides `slacktenure`, a script to fetch all users from a Slack
workspace and determine when they joined and potentially left the workspace.
This is used as a proxy for tenure with a company.

`slacktenure` takes one parameter, which is used as the title for the produced tables:

```bash
scripts/slacktenure 'Tenures at Foo Corp'
```

If omitted, the titles default to just "Tenures".

Make sure to run `slacktenure` from the project root directory, or paths will
be messed up.

## Assumptions

- An employee is assumed to have joined the company at the date of their first
  public Slack message
- They are assumed to have left the company at the date of their last public
  Slack message
- If somebody joins and leaves without ever posting a public message, they
  don't show up in the final table
- Employee numbers are assigned in ascending order of the timestamp of the
  first message; this isn't necessarily the true order, especially not for the
  first few employees &ndash; see `corrections.csv` below for a fix

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

### Tenure updates

- [`data/tenures.tsv`](data/tenures.tsv) contains the tab-separated data for
  all users with Slack ID, name, title, status, and Unix timestamp of first and
  last message, where applicable; status can be one of
  - `active`: user is still active member of the workspace
  - `alum`: user is marked `deleted` and has a timestamp for their last message
  - `fresh`: user is active member of the workspace, but hasn't posted yet
  - `noshow`: user is marked `deleted` and never posted a message
- [`data/corrections.csv`](data/corrections.csv) is an optional file containing
  corrections for known incorrect values; it uses four comma-separated columns:

  | Heading  | Meaning                                            |
  | -------- | -------------------------------------------------- |
  | `id`     | the ID of the user to which the correction applies |
  | `delete` | set to `true` if the user should be removed        |
  | `first`  | Unix timestamp for join date                       |
  | `last`   | Unix timestamp for departure date                  |
  
- [`outputs/tenures.md`](outputs/tenures.md) is the Markdown-formatted view of
  the same data with no-shows removed, and human-readable datestamps, ordered
  by date of the first message
- [`outputs/tenurescurrent.md`](outputs/tenurescurrent.md) is the
  Markdown-formatted view of the same data with only current employees
- The `diffs/*.diff` files contain the unified diffs of the TSV data between
  two updates

### Turnover graph

- [`scripts/generateturnover`](scripts/generateturnover) is an awk script that
  takes `data/tenures.tsv` as an input and produces a data file for gnuplot
  with the number of employees who have joined or left, and the employee total
  for each month
- [`data/turnover.tsv`](data/turnover.tsv) is the output of the awk script; it
  is committed so it can serve as an indicator if the graph should be
  regenerated or not
- [`scripts/turnover.gpi`](scripts/turnover.gpi) is a gnuplot script to produce
  the turnover graph with the employee total, and the monthly turnover; it
  requires a terminal type as a parameter (see `update.yml` workflow for
  examples)
- `outputs/turnover.svg` is the graph used in the README (see above)
