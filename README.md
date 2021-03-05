# Slack analyzer

- Get all users: [`users.list`](https://api.slack.com/methods/users.list)
- Filter bots and guests
  - Bots: `.is_bot`
  - Guests: `.is_restricted`
- Deactivated users: `.deleted`
- For each user:
  - Find oldest message
  - For deactivated users: also find most recent message
  - Use [`search.messages`](https://api.slack.com/methods/search.messages)
  - Query with ID: `from:<@USERID>`
