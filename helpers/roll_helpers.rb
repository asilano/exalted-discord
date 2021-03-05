module Helpers
  module RollHelpers
    def roll_pool_for_character(event, pool:, options: [])
      parsed_opts = parse_options(options)
      int_parts, non_int_parts = *(pool.split('+').partition { |part| part =~ /\A\d+\z/ })
      response = SheetsApiService.get_pools(non_int_parts, for_user_uid: event.user.id, server_uid: event.server.id)

      if response.key?('error')
        event << "There was a problem:\n```#{response['errorCode']} - #{response['error']}\n```"
        return
      end

      Mechanics::Roll.new(int_parts, non_int_parts, parsed_opts, response).roll_it
    end

    def parse_options(options)
      parsed = {}
      state = :opt
      options.each do |token|
        num = token.to_i
        case state
        when :opt
          case token.downcase
          when '-msg'
            state = :msg
          when '-nopenalty'
            parsed[:nopenalty] = true
          when '-auto'
            state = :auto
          when '-dbl'
            state = :dbl
          when '-flat10'
            parsed[:flat10] = true
          when '-botch1'
            parsed[:botch1] = true
          when '-tn'
            state = :tn
          when '-reroll'
            state = :reroll
          when '-infroll'
            state = :infroll
          end
        when :msg
          parsed[:msg] = token
          state = :opt
        when :auto
          parsed[:auto] = num
          state = :opt
        when :dbl
          next unless (7..9).cover? num

          parsed[:dbl] = num
          state = :opt
        when :tn
          parsed[:tn] = num
          state = :opt
        when :reroll, :infroll
          parsed[state] = token.split(',').map(&:to_i)
          state = :opt
        end
      end
      parsed
    end

  end
end
