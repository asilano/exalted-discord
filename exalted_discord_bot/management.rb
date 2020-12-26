require './helpers/bot_helpers'
module ExaltedDiscordBot
  module Management
    extend Discordrb::Commands::CommandContainer
    extend Helpers::BotHelpers
    include Helpers::BotHelpers::Constants

    using Helpers::BotHelpers::Patches

    command(:characters, aliases:     [:chars],
                         description: 'List your available characters, their types, castes / aspects, and concepts') do |event|
      wait_in_channel(event.channel) do
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

    command(:use, min_args:    1,
                  description: 'Activate a character, identified by (exact) name for use on this channel',
                  usage:       '^use <name>') do |event, *name_parts|
      name_parts.reprocess!
      wait_in_channel(event.channel) do
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

    command(:unuse, description: 'Stop using any character on this channel') do |event|
      wait_in_channel(event.channel) do
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
  end
end
