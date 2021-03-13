class CreateCombatant < ActiveRecord::Migration[6.0]
  def change
    create_table :combatants do |t|
      t.references :combat
      t.string :discord_user_uid
      t.string :name
      t.integer :initiative
      t.timestamps
    end
  end
end
