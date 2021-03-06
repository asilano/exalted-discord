require 'shellwords'
require_relative './roll_helpers'

module Helpers
  module BotHelpers
    module Constants
      COLOURS = {
        info:   0x569cd6,
        meta:   0x6a9955,
        roll:   0xd7ba7d,
        pay:    0xd16969,
        combat: 0xc60f0f
      }.freeze

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
      ].freeze
    end

    include Constants
    include RollHelpers

    def wait_in_channel(channel)
      wait_msg = channel.send_message('One moment...')
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

      health_numbers = response['health_levels'].map { |hl| "%2s" % [hl['penalty']] }
      damage_sym = { 'o' => '  ', 'b' => ' B', 'l' => ' L', 'a' => ' A' }
      damage = response['health_levels'].map { |hl| damage_sym[hl['damaged'][0]] }
      embed.add_field name: "\u200B", value: ("Health levels\n```\n" +
                                                health_numbers.join(' ') + "\n" +
                                                damage.join(' ') + "\n```")
    end

    module Patches
      refine Array do
        def reprocess
          join(' ').shellsplit
        end

        def reprocess!
          replace(reprocess)
        end
      end
    end
  end
end
