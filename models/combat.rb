class Combat < ActiveRecord::Base
  include Helpers::BotHelpers::Constants

  def output_to_embed(embed)
    embed.title = 'Combat'
    embed.add_field name: 'Tick', value: tick || 'Not ticking'
    embed.color = COLOURS[:combat]
  end
end