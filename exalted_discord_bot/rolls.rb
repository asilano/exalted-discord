require './mechanics/roll'
module ExaltedDiscordBot
  module Rolls
    extend Discordrb::Commands::CommandContainer
    extend Helpers::BotHelpers
    include Helpers::BotHelpers::Constants
    using Helpers::BotHelpers::Patches

    command :rnum, description: 'Roll n dice. Supports dice tricks',
                   usage:       "^rnum <count> [options]\n" \
                                "-msg <message>        # Flavour text to report with the roll\n" \
                                "-auto <num>           # Grant <num> automatic successes\n" \
                                "-dbl <7,8,9>          # Double the given number (and above)\n" \
                                "-flat10               # Rolls of 10 don't count double\n" \
                                "-botch1               # Rolls of 1 subtract a success\n" \
                                "-tn <num>             # Rolls of <num> and above are successes\n" \
                                "-reroll <num[,num]*>  # Reroll the given number(s) once\n" \
                                "-infroll <num[,num]*> # Reroll the given number(s) until they cease to appear" do |event, count, *options|
      parsed_opts = parse_options(options.reprocess)
      roll = Mechanics::Roll.new([count], [], parsed_opts, {}).roll_it
      event.channel.send_embed do |e|
        e.title = "#{event.user.nick} rolled #{roll.message(simple: true)}"
        e.description = roll.output
        e.color = COLOURS[:roll]
      end
    end

    command :roll, aliases:     [:r],
                   description: 'Roll a dice pool for your character. Supports dice tricks',
                   usage:       "^roll <pool>[+num] [options]\n" \
                                "<pool>                # The dice pool to roll. Accepts:\n" \
                                "                        * skills and combinations (Perc+Awa)\n" \
                                "                        * other stats: Ess, PermWP, TempWP\n" \
                                "                        * precalculated pools: Join, Rush, Disengage\n" \
                                "+num                  # Additional dice to roll above the base pool\n" \
                                "-msg <message>        # Flavour text to report with the roll\n" \
                                "-auto <num>           # Grant <num> automatic successes\n" \
                                "-nopenalty            # Ignore dice penalties due to Health Levels\n" \
                                "-dbl <7,8,9>          # Double the given number (and above)\n" \
                                "-flat10               # Rolls of 10 don't count double\n" \
                                "-botch1               # Rolls of 1 subtract a success\n" \
                                "-tn <num>             # Rolls of <num> and above are successes\n" \
                                "-reroll <num[,num]*>  # Reroll the given number(s) once\n" \
                                "-infroll <num[,num]*> # Reroll the given number(s) until they cease to appear\n\n" \
                                "Example: ^roll per+awa+3 -dbl 9 -reroll 6\n" \
                                " => Roll Perception + Awareness, with a 3-dice bonus. Double 9s, and reroll 6s once." do |event, pool, *options|
      wait_in_channel(event.channel) do
        roll = roll_pool_for_character(event, pool: pool, options: options.reprocess)

        if roll
          if roll.incap
            event.channel.send_embed do |e|
              e.title = "#{roll.name} couldn't roll #{roll.message}"
              e.description = 'Incapacitated'
              e.color = COLOURS[:roll]
            end
          else
            event.channel.send_embed do |e|
              e.title = "#{roll.name} rolled #{roll.message}"
              e.description = roll.output
              e.color = COLOURS[:roll]
            end
          end
        end
      end
    end
  end
end
