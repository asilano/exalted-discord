
require './helpers/bot_helpers'
require './sheets_api_service'
require './exalted_discord_bot/management'
require './exalted_discord_bot/rolls'
module ExaltedDiscordBot
  class Bot < Discordrb::Commands::CommandBot
    include Helpers::BotHelpers

    def initialize
      super(token: ENV['EXALTED_DISCORD_BOT_TOKEN'], prefix: '^', rescue: 'Sorry, something went wrong')
      include! Management
      include! Rolls
    end
  end
end
