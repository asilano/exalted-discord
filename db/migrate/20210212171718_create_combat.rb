class CreateCombat < ActiveRecord::Migration[6.0]
  def change
    create_table :combats do |t|
      t.string :channel_uid
      t.integer :tick
      t.timestamps
    end
  end
end
