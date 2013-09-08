class Guide < ActiveRecord::Base
  has_many :steps
  has_and_belongs_to_many :authors
  has_many :comments, as: :commentable

  will_publish
end

class Step < ActiveRecord::Base
  belongs_to :guide
  has_many :comments, as: :commentable
end

class Author < ActiveRecord::Base
  has_and_belongs_to_many :guides
end

class Comment < ActiveRecord::Base
  belongs_to :commentable, polymorphic: true
end