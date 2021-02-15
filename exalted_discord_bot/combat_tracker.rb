#require './mechanics/roll'
require './models/combat'

module ExaltedDiscordBot
  module CombatTracker
    extend Discordrb::Commands::CommandContainer
    extend Helpers::BotHelpers
    include Helpers::BotHelpers::Constants
    using Helpers::BotHelpers::Patches

    command(:combat,
            aliases:     [:fight],
            description: 'Start a combat in this channel') do |event|
      wait_in_channel(event.channel) do
        combat = Combat.where(channel_uid: event.channel.id).first

        if combat
          event << 'This channel is already in combat!'
        else
          combat = Combat.create(channel_uid: event.channel.id)
          event << 'Combat started!'
        end

        event.channel.send_embed do |e|
          combat.output_to_embed e
        end
      end
    end

    command(:'stop-combat',
            aliases:     [:peace],
            description: 'Stop a combat in this channel') do |event|
      wait_in_channel(event.channel) do
        combat = Combat.where(channel_uid: event.channel.id).first

        if combat
          combat.destroy
          event << 'Combat ended.'
          event << '(A summary might go here.)'
        else
          event << "This channel isn't in combat!"
        end
      end
    end
  end
end
