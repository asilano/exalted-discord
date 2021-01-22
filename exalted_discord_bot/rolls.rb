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
      r = Mechanics::Roll.new(count, parsed_opts[:roll])
      event.channel.send_embed do |e|
        e.title = "#{response['char_name']} rolled #{parsed_opts[:display][:msg] || count.to_s + 'dice'}"
        e.description = r.output
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
      parsed_opts = parse_options(options.reprocess)
      int_parts, non_int_parts = *(pool.split('+').partition { |part| part =~ /\A\d+\z/ })
      response = SheetsApiService.get_pools(non_int_parts, for_user_uid: event.user.id, server_uid: event.server.id)

      if response.key?('error')
        event.channel.send_message("There was a problem:\n```#{response['errorCode']} - #{response['error']}\n```")
      else
        incap = response['penalty'] == 'incap'

        message = response['parsed_pool']
        message << ', wounded' if (incap || response['penalty'].negative?) && !parsed_opts[:roll][:nopenalty]
        message << " + #{int_parts.join('+')}" unless int_parts.empty?

        count = non_int_parts.map { |part| response[part].to_i }.sum + int_parts.map(&:to_i).sum
        count += response['penalty'].to_i unless parsed_opts[:roll][:nopenalty]
        if incap || count <= 0
          description = incap ? 'Incapacitated' : 'Excessively wounded'

          event.channel.send_embed do |e|
            e.title = "#{response['char_name']} couldn't roll #{parsed_opts[:display][:msg] || message}"
            e.description = description
            e.color = COLOURS[:roll]
          end
        else
          r = Mechanics::Roll.new(count, parsed_opts[:roll])

          event.channel.send_embed do |e|
            e.title = "#{response['char_name']} rolled #{parsed_opts[:display][:msg] || message}"
            e.description = r.output
            e.color = COLOURS[:roll]
          end
        end
      end
    end

    def self.parse_options(options)
      parsed = { display: {}, roll: {} }
      state = :opt
      options.each do |token|
        num = token.to_i
        case state
        when :opt
          case token.downcase
          when '-msg'
            state = :msg
          when '-nopenalty'
            parsed[:roll][:nopenalty] = true
          when '-auto'
            state = :auto
          when '-dbl'
            state = :dbl
          when '-flat10'
            parsed[:roll][:flat10] = true
          when '-botch1'
            parsed[:roll][:botch1] = true
          when '-tn'
            state = :tn
          when '-reroll'
            state = :reroll
          when '-infroll'
            state = :infroll
          end
        when :msg
          parsed[:display][:msg] = token
          state = :opt
        when :auto
          parsed[:roll][:auto] = num
          state = :opt
        when :dbl
          next unless (7..9).cover? num

          parsed[:roll][:dbl] = num
          state = :opt
        when :tn
          parsed[:roll][:tn] = num
          state = :opt
        when :reroll, :infroll
          parsed[:roll][state] = token.split(',').map(&:to_i)
          state = :opt
        end
      end
      parsed
    end
  end
end
