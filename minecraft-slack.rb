require "net/http"
require "uri"
require 'json'
require 'yaml'

class MinecraftSlack
  attr_accessor :config
  attr_reader :users

  def initialize(config)
    @config = config
    load_users
    save
  end

  def user_regex
    Regexp.new("\<(#{users.keys.join("|")})\>")
  end

  def change_icon?(text)
    text.downcase[0,20] == "change slack icon to"
  end

  def change_name?(text)
    text.downcase[0,20] == "change slack name to"
  end

  def change_icon(chat_line)
    puts "Changing #{chat_line.user} icon to #{chat_line.new_icon}"
    users[chat_line.user]["icon"] = chat_line.new_icon
    save
  end

  def change_name(chat_line)
    puts "Changing #{chat_line.user} name to #{chat_line.new_name}"
    config[chat_line.user]["username"] = chat_line.new_name
    save
  end

  def post_message(chat_line)
    info = users[chat_line.user]
    puts "Posting to slack: <#{chat_line.user}> #{chat_line.line}"
    Net::HTTP.post_form(uri, payload(info["username"], info["icon"], chat_line.line))
  end

  def voodoo_chicken(chat_line)
    if five_percent_chance
      puts "Summoning Ultra Mega Chicken"
      `c="screen -p 0 -S minecraft_server -X eval 'stuff \\"say #{chat_line.user} has summonded Ultra Mega Chicken!\\"\\015'"; su minecraft -c "$c"`
      `c="screen -p 0 -S minecraft_server -X eval 'stuff \\"execute #{chat_line.user} ~ ~ ~ summon Chicken\\"\\015'"; su minecraft -c "$c"`
    end
  end

  private

  def five_percent_chance
    (1..20).to_a.sample == 7
  end

  def save
    File.write(File.join(minecraft_path, "minecraft-slack.yml"), YAML.dump(config))
  end

  def minecraft_path
    config.fetch("minecraft_path")
  end

  def uri
    URI.parse(config.fetch("slack_api"))
  end

  def load_whitelist
    file = File.join(minecraft_path, "whitelist.json")
    unless File.exist?(file)
      File.write(file, [].to_json)
    end

    JSON.load(File.new(file)).map {|u| u["name"]}
  end

  def load_users
    whitelist = load_whitelist || []
    user_data = config.reject do |k,v|
      ["minecraft_path", "slack_api"].include?(k)
    end

    @users = whitelist.map do |username|
      data = user_data.fetch(username, {
        "username" => username,
        "icon" => ":steve:"
      })

      {username => data}
    end.reduce(:merge)
    config.merge!(users)
  end

  def payload(username, icon, text)
    {
      "payload" => {
        "username" => username,
        "icon_emoji" => icon,
        "text" => text
      }.to_json
    }
  end
end

class ChatLine
  attr_reader :user, :line

  def initialize(line, user)
    @line = line.gsub(/.*#{user}/,'').strip
    @user = user[1..-2]
  end

  def change_icon?
    line.downcase[0,20] == "change slack icon to"
  end

  def change_name?
    line.downcase[0,20] == "change slack name to"
  end

  def voodoo_chicken?
    line.downcase[0,13] == "chicken arise" ||
    line.downcase[0,13] == "arise chicken"
  end

  def new_icon
    line[20,99].strip
  end

  def new_name
    line[20,99].strip
  end
end

config   = YAML.load_file("minecraft-slack.yml")
mc_slack = MinecraftSlack.new(config)
line = $_

if match = mc_slack.user_regex.match(line)
  chat_line = ChatLine.new(line, match[0])

  case
  when chat_line.change_icon?
    mc_slack.change_icon(chat_line)
  when chat_line.change_name?
    mc_slack.change_name(chat_line)
  when chat_line.voodoo_chicken?
    mc_slack.voodoo_chicken(chat_line)
  else
    mc_slack.post_message(chat_line)
  end
end
