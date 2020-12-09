require 'byebug'
require 'discordrb'
require 'active_support/core_ext/string'
require './exalted_discord_bot/bot'
require './sheets_api_service'

COLOURS = {
  info: 0x569cd6,
  meta: 0x6a9955
}

ABILITIES = %w[
  archery
  athletics
  awareness
  brawl
  bureaucracy
  craft
  dodge
  integrity
  investigation
  larceny
  linguistics
  lore
  martial_arts
  medicine
  melee
  occult
  performance
  presence
  resistance
  ride
  sail
  socialise
  stealth
  survival
  thrown
  war
]

def wait(event)
  wait_msg = event.channel.send_message('One moment...')
  yield
  wait_msg.delete
end

def character_summary(response, embed)
  embed.add_field name: response['name'], value: "#{response['caste']} #{response['spark'].titleize} - #{response['concept']}"

  phys = %w[strength dexterity stamina].map do |attr|
    "**#{attr.titleize}**: #{'◉' * response[attr]}#{'◯' * (5 - response[attr])}"
  end.join("\n")
  social = %w[charisma manipulation appearance].map do |attr|
    "**#{attr.titleize}**: #{'◉' * response[attr]}#{'◯' * (5 - response[attr])}"
  end.join("\n")
  mental = %w[perception intelligence wits].map do |attr|
    "**#{attr.titleize}**: #{'◉' * response[attr]}#{'◯' * (5 - response[attr])}"
  end.join("\n")

  embed.add_field name: "\u200B", value: phys, inline: true
  embed.add_field name: "\u200B", value: social, inline: true
  embed.add_field name: "\u200B", value: mental, inline: true

  strong_abils = ABILITIES.select { |abil| response[abil] >= 3 }
  unless strong_abils.empty?
    embed.add_field name: "\u200B", value: 'Strong abilities'
    strong_abils.each_slice((strong_abils.length / 3).ceil).map do |chunk|
      chunk.map do |abil|
        "**#{abil.titleize}**: #{'◉' * response[abil]}#{'◯' * (5 - response[abil])}"
      end.join("\n")
    end.each do |col|
      embed.add_field name: "\u200B", value: col, inline: true
    end
  end
end

bot = Discordrb::Commands::CommandBot.new token: ENV['EXALTED_DISCORD_BOT_TOKEN'], prefix: '^'

bot.command(%i[characters chars], rescue: 'Sorry, something went wrong') do |event|
  wait(event) do
    response = SheetsApiService.character_list(for_user_uid: event.user.id)
    if response.key?('error')
      event.channel.send_message("There was a problem:\n```#{response['errorCode']} - #{response['error']}\n```")
    else
      event.channel.send_embed do |e|
        e.title = "#{event.user.nick}'s characters"
        e.add_field name: "\u200B", value: response['characters'].map { |char| "#{char['name']} - #{char['caste']} #{char['spark'].titleize} - #{char['concept']}" }.join("\n")
        e.color = COLOURS[:info]
      end
    end
  end
end

bot.command(:use, min_args: 1, rescue: 'Sorry, something went wrong') do |event, *name_parts|
  wait(event) do
    response = SheetsApiService.use_character(for_user_uid: event.user.id, name: name_parts.join(' '), server_uid: event.server.id)
    if response.key?('error')
      event.channel.send_message("There was a problem:\n```#{response['errorCode']} - #{response['error']}\n```")
    else
      event.channel.send_embed do |e|
        e.title = "#{response['name']} activated"
        e.description = "#{event.user.nick} is now using #{response['name']} on this channel"
        character_summary(response, e)
        e.color = COLOURS[:meta]
      end
    end
  end
end

bot.command(:unuse, rescue: 'Sorry, something went wrong') do |event|
  wait(event) do
    response = SheetsApiService.unuse_character(for_user_uid: event.user.id, server_uid: event.server.id)
    if response.key?('error')
      event.channel.send_message("There was a problem:\n```#{response['errorCode']} - #{response['error']}\n```")
    else
      event.channel.send_embed do |e|
        e.title = "Character deactivated"
        e.description = "#{event.user.nick} is no longer using a character on this channel"
        e.color = COLOURS[:meta]
      end
    end
  end
end

bot.command :rnum do |event, count|
  rolls = Array.new(count.to_i) { rand(1..10) }.sort.reverse
  success = rolls.count { |r| r >= 7 } + rolls.count(10)
  "#{event.user.name} rolled #{success} successes (on #{count} dice: [#{rolls.join(', ')}]"
end

bot.command :r do |event, *pools|
  char = Character.find_by(discord_user: event.user.id)
  pool = pools.map { |attr| char.send(attr.downcase) }.inject(&:+)
  rolls = Array.new(pool.to_i) { rand(1..10) }.sort.reverse
  success = rolls.count { |r| r >= 7 } + rolls.count(10)
  "#{event.user.nick} rolled #{pools.join(' + ')}. #{success} successes (on #{pool} dice: [#{rolls.join(', ')}]"
end

at_exit { bot.stop }
bot.run
