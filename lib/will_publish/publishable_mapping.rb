module WillPublish
  class PublishableMapping < ActiveRecord::Base
    belongs_to :draft, polymorphic: true
    belongs_to :published, polymorphic: true
  end
end