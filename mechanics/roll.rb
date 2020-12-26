module Mechanics
  class Roll
    def initialize(count, options)
      @count = count
      @options = options
    end

    def output
      roll_it
      "#{@success} successes (#{"with #{@options[:auto]} automatic " if @options[:auto]&.positive?}on #{@count} dice: [#{@rolls.map { |d| format(d) }.join(', ')}])"
    end

    private

    def roll_it
      @rolls = Array.new(@count.to_i) { Die.new(@options) }.sort.reverse
      @success = @rolls.count { |d| d.type == :single }
      @success += 2 * @rolls.count { |d| d.type == :double }
      @success -= @rolls.count { |d| d.type == :botch }
      @success += @options[:auto] if @options[:auto]
    end

    def format(die)
      wrap = case die.type
             when :single
               '**'
             when :double
               '__**'
             when :botch
               '*'
             end
      "#{wrap}#{die.face}#{wrap&.reverse}#{" (~~#{die.rerolled.map(&:to_s).join(',')}~~)" unless die.rerolled.empty?}"
    end
  end

  class Die
    attr_reader :face, :type, :rerolled
    def initialize(options)
      @face = rand(1..10)
      @rerolled = []

      if options[:reroll]&.include?(@face)
        @rerolled << @face
        @face = rand(1..10)
      end
      while options[:infroll]&.include?(@face)
        @rerolled << @face
        @face = rand(1..10)
      end

      @type = case @face
              when ((options[:dbl] || 10)..(options[:flat10] ? 0 : 10))
                :double
              when ((options[:tn] || 7)..10)
                :single
              when (1..(options[:botch1] ? 1 : 0))
                :botch
              else
                :fail
              end
    end

    def <=>(other)
      @face <=> other.face
    end
  end
end
