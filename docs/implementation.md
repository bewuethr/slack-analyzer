# Implementation notes

Scripts live in the `scripts` subdirectory.

All functionality is spread over a Bash script (`slacktenure`), two awk scripts
(`generateturnover` and `stats`), and two gnuplot scripts (`turnover.gpi` and
`durationboxplot.gpi`). Three steps in the composite run steps action defined
in `action.yml` tie everything together.

`corrtool` is a helper script to generate entries for and validate
`corrections.csv`.

## Update user data and generate a diff

`slacktenure` gets the list of all users from the Slack workspace, and throws
away bot users and restricted users (guests). The workspace is determined by
the Slack API bot token, which is required to be set in the environment as
`$BOT_TOKEN`.

The user list is stored in an intermediate file, `users.json`.

The core functionality of updating users lives in the `tenureupdate` function.
After writing the headers later used in `tenures.tsv`, it loops over the output
of the `extractids` function, which pulls user IDs, names, active status, and
titles out of `users.json`.

Then, for each user:

- gets an entry from the corrections file, if one exists
- skips to the next entry if the correction file indicates the user should be
  deleted
- compares current and new status; if there is no current status, the user is
  considered fresh
- if a user was previously active and is now deleted, it gets the timestamp of
  their most recent message; this requires a Slack API user token to be set in
  the environment as `$USER_TOKEN`
- if the user is fresh, it checks if they have posted, and if so, updates them
  to active (unless the user has been deleted without ever posting, making them
  a no-show)
- applies corrections for first and last timestamp where available
- prints the updated and corrected vales to `tenures_new.tsv`

The intermediate `users.json` is now deleted, and a file containing the unified
diff between `tenures_new.tsv` and `tenures.tsv` is generated. This also
generates diff subdirectories for year and month if needed; if the diff file is
empty, it is deleted again, and we exit. `tenures_new.tsv` is now renamed to
`tenures.tsv`.

Finally, the main README is generated containing the link to the latest diff;
if there is no corrections file, the lines mentioning it are filtered.

The Markdown tables are generated from `tenures.tsv` by removing the header
row, sorting by the appropriate fields, and adding an employee number before
inserting table markup. The table with tenures ordered by duration takes the
difference between join date and departure/current date to determine the tenure
duration in days.

The company name used in the tables and the README is taken from the argument
provided to `slacktenure`.

For more details about the corrections file, see [Manually correcting data from
Slack][1].

[1]: <corrections.md>

### Known bugs

- If a fresh user writes their first message shortly before being removed, they
  are considered a no-show, even though they wrote messages
- Double quotes in `tenures.tsv` break the GitHub pretty-printing, so they are
  replaced with single quotes

## Generate input data for the turnover graph

`generateturnover` is an awk script that produces input for the gnuplot script
to produce the turnover graph; it relies on GNU extensions such as array
sorting and nested arrays.

For each entry, awk converts the Unix timestamps to `YYYY-MM` format (which
requires consistently using the same timezone everywhere), and counts how many
first and last timestamps have occurred per month, representing people joining
and leaving in that month.

After going through all users, the script iterates over the months and prints
the totals, as well as a running total.

## Generate a turnover graph

`turnover.gpi` is a gnuplot script to create a combined bar and line graph from
the output of `generateturnover`. It takes a parameter to determine both
terminal type and extension of the output; this way, it can be used for both
SVG output for the README and PNG output for the Telegram message.

It draws four data series:

- a line for the total employee count
- labels for the total employee count, on every sixth value
- boxes for new employees who joined each month
- boxes on the negative y-axis for employees who left each month

The y-axis is labelled on both sides for every 50, but there are grid lines for
every 10.

## Generate statistics and a boxplot

The `stats` awk script expects a single column of input and produces statistics
with min/max values, mean, and median. The output is shown as a table in the
generated README. The script is called from `slacktenure` using some of the
prettyprint functions.

`durationboxplot.gpi` expects the same input as `stats` and generates a boxplot
for that data; it reads the data from standard input so no intermediate file is
required.

## Tying everything together in a composite run steps action

In `action.yml`, three run steps tie everything together.

The first step runs `slacktenure` using the required `name` input as the
parameter. If nothing changed, it exits.

Else, the updated `tenures.tsv` file and the diff are committed and pushed.

The rest of the first step is preparing the diff output to be used in a
Telegram message:

- The URLs for the updated files are generated
- The diff message is JSON-escaped
- The `diff-msg` output is set
- The `continue` environment variable is set to `true`

The second step generates the graph, but only when required: if `continue` is
not `true`, it exits. Notice that composite run steps can't use an `if:` field,
so the check happens in the Bash script.

Then, `generateurnover` is run; if this modifies `turnover.tsv`, gnuplot is
installed and the `turnover.gpi` script is run, once for SVG, and once for PNG.

The new files are committed, and the `path` output is set to the path of the
PNG graph; as an output of the action overall, it's called `graph-path`.

See the [main README][2] for a usage example of the outputs to send Telegram
messages.

The third step also installs gnuplot (unless that happened in the second step
already), then sources `slacktenure` (which is written to not execute anything
when sourced so it doubles as a library) and uses functions to produce input
for `durationboxplot.gpi`. Then, the boxplot is generated and committed if it
has changed.

[2]: <../README.md>

## Corrections helper script

`corrtool` is a Bash script providing two subcommands, `add` and `check`. `add`
prompts for input and runs some validation before generating a new entry to add
to `corrections.csv`; `check` calls an awk script that checks every entry for
validity, looking for

- Correct header line
- Correct number of fields of every record
- Uniqueness of Slack user IDs
- Correct values for the `delete` field (`true` or empty)
- Last timestamp not occurring before the first one
- Valid timestamp format

`corrtool` is called in the first run step in `action.yml` if `corrections.csv`
exists.
