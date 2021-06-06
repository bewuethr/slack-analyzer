# Manually correcting data from Slack

The data fetched from Slack can be inaccurate for a number of reasons:

- A company might have existed for a while before starting to use Slack, so all
  the start dates of employees before that would be wrong
- The first or last message or way off the real date of joining/leaving the
  company
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
3. The corrected timestamp of the first message
4. The corrected timestamp of the last message

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
- For user `U00000002`, the timestamp of the first message is corrected to
  `1422766800` (2015-02-01, using EST timezone)
- User `U00000003` gets their last message timestamp set to `1607144400` (2020-12-05)
- User `U00000004` get both first and last message corrected, to `1562817600`
  (2019-07-11) and `1610082000` (2021-01-08)

If `corrections.csv` is found in `data`, it is mentioned and linked to in the
main README file.
