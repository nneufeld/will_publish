class Guide < ActiveRecord::Base
  has_many :steps
  has_and_belongs_to_many :authors
  has_many :comments, as: :commentable

  will_publish

  # some accessors to help with testing callbacks
  attr_accessor :callback_order
  attr_accessor :return_false_before_publish
  attr_accessor :return_false_after_publish
  attr_accessor :raise_exception_after_publish

  before_publish do |guide|
    (guide.callback_order ||= []) << "before"
    !return_false_before_publish
  end

  around_publish :do_around_publish
  after_publish :do_after_publish

  def do_around_publish
    self.callback_order << "around before"
    yield
    self.callback_order << "around after"
  end

  def do_after_publish
    self.callback_order << "after"
    raise "After pubish error!" if raise_exception_after_publish
    return !return_false_after_publish
  end
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