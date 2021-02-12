require 'byebug'
require 'discordrb'
require './lib/db_connection'
require 'active_support/core_ext/string'
require './exalted_discord_bot/bot'

bot = ExaltedDiscordBot::Bot.new

at_exit { bot.stop }
bot.run
