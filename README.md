# Minecraft Slack
Store minecraft chats in slack with a vanilla mc server. This only works with servers using a whitelist, and uses the whitelist for authentication.

## Installation

**1.** Download repo into your minecraft directory:

```
$ cd minecraft
$ git clone https://github.com/dillonhafer/minecraft-slack.git
```

**2.** Copy config file:

```
$ cp minecraft-slack.yml{.example,}
```

**3.** Edit config file values:

`minecraft_path` should be set to the directory you cloned.

`slack_api` should be the url of an incoming webhook from Slack.

## Running

```
$ cd minecraft
$ tail -n0 -f logs/latest.log | ruby -n minecraft-slack.rb
```