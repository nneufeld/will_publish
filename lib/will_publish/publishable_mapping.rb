module WillPublish
  class PublishableMapping < ActiveRecord::Base
    belongs_to :draft, polymorphic: true
    belongs_to :published, polymorphic: true

    validates :draft_id, :draft_type, :published_id, :published_type, presence: true

    validates :draft_id, uniqueness: { scope: [ :draft_type ] }
    validates :published_id, uniqueness: { scope: [ :published_type ] }

    def self.for_draft(draft)
      where(draft_type: draft.class.name, draft_id: draft.id).first
    end

    def self.for_published(published)
      where(published_type: published.class.name, published_id: published.id).first
    end
  end
end