ActiveRecord::Schema.define version: 1 do
  create_table :guides, force: true do |t|
    t.string :name
    t.text :description

    t.timestamps
  end

  create_table :steps, force: true do |t|
    t.integer :guide_id
    t.string :name
    t.text :description

    t.timestamps
  end

  create_table :authors, force: true do |t|
    t.string :first_name
    t.string :last_name

    t.timestamps
  end

  create_table :authors_guides, force: true do |t|
    t.integer :author_id
    t.integer :guide_id
  end

  create_table :comments, force: true do |t|
    t.string :commentable_type
    t.integer :commentable_id
    t.string :title
    t.text :body

    t.timestamps
  end

end