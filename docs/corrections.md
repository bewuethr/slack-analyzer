# Manually correcting data from Slack

The data fetched from Slack can be inaccurate for a number of reasons:

- A company might have existed for a while before starting to use Slack, so all
  the start dates of employees before that would be wrong
- The first or last message or way off the real date of joining/leaving the
  company
- The fallback value of "current time" for users without a first/last message
  might be incorrect
- A guest was accidentally added as a full user, but never actually worked at
  the company
- A contractor becomes a full-time employee, but has multiple Slack users
  instead of just one

All this can be fixed by dropping a file `corrections.csv` into the `data`
directory. It allows for modifying start and end dates, as well as removing
users entirely.

## File format

`corrections.csv` consists of four comma-separated columns, with one header
row. There most be no blank lines, and there are no comments. The columns are,
in order:

1. Slack user ID as seen in `tenures.tsv`
2. Deletion indicator (`true` to delete, else empty)
3. The corrected timestamp of their join date
4. The corrected timestamp of their departure date

Empty fields for timestamp values mean that the original value is being used.

If the second field is set to `true`, the timestamps are ignored as the user
won't show up in the results at all.

Timestamps are in seconds since the Unix epoch. They can be determined using
`date`: for example, if somebody's last message was really on 2021-05-01, the
corresponding timestamp can be produced using

```console
$ date --date=2021-05-01 +%s
1619841600
```

Notice that this is affected by the timezone; make sure that the GitHub Actions
workflow uses the same timezone, or else dates might be off by one day.

## An example file

```csv
id,delete,first,last
U00000001,true,,
U00000002,,1422766800,
U00000003,,,1607144400
U00000004,,1562817600,1610082000
```

This does the following:

- User `U00000001` gets deleted and won't show up in the output
- For user `U00000002`, the timestamp of the join date is corrected to
  `1422766800` (2015-02-01, using EST timezone)
- User `U00000003` gets their departure date timestamp set to `1607144400`
  (2020-12-05)
- User `U00000004` get both join and departure date corrected, to `1562817600`
  (2019-07-11) and `1610082000` (2021-01-08)

If `corrections.csv` is found in `data`, it is mentioned and linked to in the
main README file.

## `corrtool`

`corrtool` is a little tool to generate new entries for `corrections.csv`, and
to check the validity of a corrections file.

`corrtool add` prompts for user input and prints the new entry to standard
output:

```console
$ corrtool add
Slack user ID: 123456
Delete? (y/N): y
Joined [YYYY-MM-DD]: 2021-01-01
Left [YYYY-MM-DD]: 2021-03-02
123456,true,1609477200,1614661200
```

To append to an existing corrections file and also print to standard output,
use

```sh
corrtool add | tee -a path/to/corrections.csv
```

`corrtool check FILE` checks an existing file and prints an error message if
something is not right:

```console
$ corrtool check path/to/corrections.csv
line 5: duplicate ID U0111111125
```

This is called in `action.yml` and causes the action to exit if the corrections
file isn't properly formatted.
