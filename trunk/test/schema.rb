ActiveRecord::Schema.define(:version => 1) do
  create_table :entries, :force => true do |t|
    t.column :title,      :string
    t.column :body,       :text
    t.column :created_at, :datetime
  end
  
  create_table :comments, :force => true do |t|
    t.column :entry_id,   :integer
    t.column :body,       :text
    t.column :replied_on, :datetime
  end
end