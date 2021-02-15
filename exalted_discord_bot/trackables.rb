require './helpers/bot_helpers'
module ExaltedDiscordBot
  module Trackables
    extend Discordrb::Commands::CommandContainer
    extend Helpers::BotHelpers
    include Helpers::BotHelpers::Constants

    using Helpers::BotHelpers::Patches

    TRACKABLE_FULL_NAMES = {
      'wp'      => 'Willpower',
      'pers'    => 'motes of Personal Essence',
      'periph'  => 'motes of Peripheral Essence',
      'anima'   => 'levels of Anima Banner',
      'xp'      => 'Experience Points',
      'sparkxp' => 'Spark Experience Points',
      'limit'   => 'points of Limit'
    }.freeze

    command(:pay, description: 'Pay an amount of resource',
                  parameters: ['Amount to pay', 'Resource - one of: wp, pers, periph, anima, limit, xp, sparkxp'],
                  arg_types: [Integer, String]) do |event, amount, resource|
      wait_in_channel(event.channel) do
        response = SheetsApiService.pay_resource(amount, resource, for_user_uid: event.user.id, server_uid: event.server.id)
        if response.key?('error')
          event << "There was a problem:\n```#{response['errorCode']} - #{response['error']}\n```"
        else
          event.channel.send_embed do |e|
            e.title = "#{response['char_name']} paid #{amount} #{TRACKABLE_FULL_NAMES[resource]}"
            e.add_field name: "\u200B", value: "#{response['new_value']} remaining"
            e.color = COLOURS[:pay]
          end
        end
      end
    end
    command(:gain, description: 'Gain an amount of resource',
                  parameters: ['Amount to gain', 'Resource - one of: wp, pers, periph, anima, limit, xp, sparkxp'],
                  arg_types: [Integer, String]) do |event, amount, resource|
      wait_in_channel(event.channel) do
        response = SheetsApiService.gain_resource(amount, resource, for_user_uid: event.user.id, server_uid: event.server.id)
        if response.key?('error')
          event << "There was a problem:\n```#{response['errorCode']} - #{response['error']}\n```"
        else
          event.channel.send_embed do |e|
            e.title = "#{response['char_name']} gained #{amount} #{TRACKABLE_FULL_NAMES[resource]}"
            e.add_field name: "\u200B", value: "#{response['new_value']} remaining"
            e.color = COLOURS[:gain]
          end
        end
      end
    end
  end
end
