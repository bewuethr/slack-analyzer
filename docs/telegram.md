# Publishing updates to a Telegram channel

Posting diffs and the graph to a Telegram channel requires a few steps, and
though they're not super complicated, I didn't find them described succinctly
anywhere.

## Create a new Telegram bot and get the authorization token

This is documented in the [BotFather documentation][1].

- Start a chat with the BotFather account
- Create a new bot by sending `/newbot` as a message
- Follow the prompts to add name and username for the bot
- Copy the token from the response and stick it, for example, into a GitHub
  Actions secret
- Use `/mybots` to add a profile picture for bonus points

[1]: <https://core.telegram.org/bots#6-botfather>

## Create a new Telegram channel and get its ID

- Create a new Telegram channel, via mobile app, desktop app, or web client;
  making it private is probably a reasonable idea
- Add your new bot via "Add members"
- Post a message in the channel; the [`getUpdates`][2] method only shows updates
  from the last 24 hours
- Make a GET request to `https://api.telegram.org/bot<token>/getUpdates`; the
  response looks something like this:

    ```json
    {
      "ok": true,
      "result": [
        {
          "update_id": 808628153,
          "channel_post": {
            "message_id": 15,
            "sender_chat": {
              "id": -1001310120257,
              "title": "My new channel",
              "type": "channel"
            },
            "chat": {
              "id": -1001310120257,
              "title": "My new channel",
              "type": "channel"
            },
            "date": 1623113410,
            "text": "The message"
          }
        }
      ]
    }
    ```

  where the ID we're looking for is `-1001310120257` (including the dash!)

  For a more general case with potentially multiple channels, we can automate
  the extraction using jq, as long as we know the channel title:

    ```sh
    curl --silent "https://api.telegram.org/bot$(< token)/getUpdates" \
        | jq --arg title 'My new channel' '
            .result |
            map(
                select(.channel_post.chat.title == $title)
            )[0].channel_post.chat.id
        '
    ```

  This requires the authorization token to be stored in a file named `token` in
  the current directory.

[2]: <https://core.telegram.org/bots/api#getupdates>
