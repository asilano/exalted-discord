#require './mechanics/roll'
require './models/combat'
require './models/combatant'

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

    command(:join,
            description: "Add your active character to the combat in this channel.\n" \
                         "Rolls Join Battle + 3 for starting initiative, accepting dice tricks.\n" \
                         "For details, see ^help roll.\n" \
                         "Also accepts '^join -at <num>' to join at a given initiative without rolling.") do |event, *options|
      wait_in_channel(event.channel) do
        combat = Combat.where(channel_uid: event.channel.id).first

        unless combat
          event << "This channel isn't in combat!"
          break
        end

        if combat.combatants.where(discord_user_uid: event.user.id).present?
          event << "#{event.user.nick} is already in this combat!"
          break
        end

        roll = roll_pool_for_character(event, pool: 'join', options: options.reprocess + ['-auto', '3'])
        combat.combatants.create(discord_user_uid: event.user.id, name: roll.name, initiative: roll.success)

        event.channel.send_embed do |e|
          e.title = "#{roll.name} rolled #{roll.message}"
          e.description = roll.output
          e.color = COLOURS[:roll]
        end
        event.channel.send_embed do |e|
          combat.output_to_embed e
        end
      end
    end

    command(:flee,
            description: "Remove your active character from the combat in this channel.") do |event, *options|
      wait_in_channel(event.channel) do
        combat = Combat.where(channel_uid: event.channel.id).first

        unless combat
          event << "This channel isn't in combat!"
          break
        end

        combatant = combat.combatants.where(discord_user_uid: event.user.id).first

        unless combatant
          event << "#{event.user.nick} is not in this combat!"
          break
        end

        combatant.destroy

        event.channel.send_embed do |e|
          combat.reload.output_to_embed e
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
