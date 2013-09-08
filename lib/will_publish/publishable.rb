module WillPublish
  module Publishable

    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods

      def will_publish
        extend PublishableClassMethods
        include InstanceMethods
      end

    end

    module PublishableClassMethods

      SYSTEM_ATTRIBUTES = %w(id created_at updated_at)

      def attributes_to_reject
        SYSTEM_ATTRIBUTES
      end
    end

    module InstanceMethods

      def publish
        published_version = self.published
        published_version ||= self.class.new
        published_version.attributes = attributes_to_copy.merge(is_published_version: true)
        published_version.save!
        WillPublish::PublishableMapping.create(draft: self, published: published_version)
      end

      def published
        WillPublish::PublishableMapping.where(draft_type: self.class.name, draft_id: self.id).first.try(:published)
      end

      def draft
        WillPublish::PublishableMapping.where(published_type: self.class.name, published_id: self.id).first.try(:draft)
      end

      private

      def attributes_to_copy
        self.attributes.reject{|k,v| self.class.attributes_to_reject.include?(k) }
      end

    end

  end
end

ActiveRecord::Base.send(:include, WillPublish::Publishable)