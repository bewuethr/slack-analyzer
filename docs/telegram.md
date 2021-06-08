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
