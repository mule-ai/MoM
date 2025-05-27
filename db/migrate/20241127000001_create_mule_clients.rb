class CreateMuleClients < ActiveRecord::Migration[8.0]
  def change
    create_table :mule_clients do |t|
      t.string :name, null: false
      t.string :host, null: false
      t.integer :port, null: false
      t.string :status, default: 'unverified'
      t.datetime :last_heartbeat
      t.text :capabilities

      t.timestamps
    end

    add_index :mule_clients, [:host, :port], unique: true
    add_index :mule_clients, :status
  end
end