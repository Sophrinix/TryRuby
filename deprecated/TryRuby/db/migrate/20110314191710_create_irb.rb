class CreateIrb < ActiveRecord::Migration
  def self.up
    create_table :irb do |t|

      t.timestamps
    end
  end

  def self.down
    drop_table :irb
  end
end
