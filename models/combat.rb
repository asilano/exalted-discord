class Combat < ActiveRecord::Base
  include Helpers::BotHelpers::Constants

  has_many :combatants, -> { order('initiative DESC') }

  def output_to_embed(embed)
    embed.title = 'Combat'
    embed.add_field name: 'Tick', value: tick || 'Not ticking'
    embed.color = COLOURS[:combat]

    return if combatants.blank?

    embed.add_field name: 'Initiative',
                    value: combatants.map { |c| "#{c.initiative}: #{c.name}" }.join("\n")
  end
end
