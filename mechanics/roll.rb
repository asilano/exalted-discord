module Mechanics
  class Roll
    attr_reader :name, :incap, :success

    def initialize(int_parts, non_int_parts, options, response)
      @int_parts = int_parts
      @non_int_parts = non_int_parts
      @options = options
      @response = response
      @name = response['char_name']
    end

    def roll_it
      if @response['penalty'] == 'incap'
        @incap = true
        return
      end

      perform
      self
    end

    def message(simple: false)
      return @options[:msg] if @options[:msg].present?
      return "#{@count} dice" if simple

      message = @response['parsed_pool']
      message << ", wounded #{@response['penalty']}" if @response['penalty'].negative? && !@options[:nopenalty]
      message << " + #{@int_parts.join('+')}" unless @int_parts.empty?
      message
    end

    def output
      "#{@success} successes (#{"with #{@options[:auto]} automatic " if @options[:auto]&.positive?}on #{@count} dice: [#{@rolls.map { |d| format(d) }.join(', ')}])"
    end

    private

    def perform
      @count = count
      @rolls = Array.new(@count) { Die.new(@options) }.sort.reverse
      @success = @rolls.count { |d| d.type == :single }
      @success += 2 * @rolls.count { |d| d.type == :double }
      @success -= @rolls.count { |d| d.type == :botch }
      @success += @options[:auto] if @options[:auto]
    end

    def count
      [@non_int_parts.map { |part| @response[part].to_i }.sum +
        @int_parts.map(&:to_i).sum +
        (@response['penalty'].to_i unless @options[:nopenalty]),
       0].max
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
