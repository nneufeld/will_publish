module WillPublish
  module Publishable

    class PublishCallbackException < StandardError; end

    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods

      def will_publish(options = {})
        # add support for callbacks
        include ActiveSupport::Callbacks
        define_callbacks :publish, terminator: ->(target, result) { result == false }
        extend CallbackMethods

        cattr_accessor :except
        self.except = options[:except] || {}

        cattr_accessor :only
        self.only = options[:only] || {}

        include InstanceMethods
      end

    end

    module CallbackMethods
      # This comes straight from the ActiveModel callbacks code:
      # https://github.com/rails/rails/blob/4-1-stable/activemodel/lib/active_model/callbacks.rb
      def before_publish(*args, &block)
        set_callback(:publish, :before, *args, &block)
      end

      def after_publish(*args, &block)
        options = args.extract_options!
        options[:prepend] = true
        conditional = ActiveSupport::Callbacks::Conditionals::Value.new { |v|
          v != false
        }
        options[:if] = Array(options[:if]) << conditional
        set_callback(:publish, :after, *(args << options), &block)
      end

      def around_publish(*args, &block)
        set_callback(:publish, :around, *args, &block)
      end
    end

    module InstanceMethods

      def publish
        begin
          transaction do
            raise PublishCallbackException unless run_callbacks(:publish) do
              published = self.published_version || self.class.new
              published.attributes = Attributes.attributes_to_copy(self, self.only, self.except).merge(is_published_version: true)
              published.save!

              Associations.copy_associations(self, published, self.only, self.except)

              PublishableMapping.create!(draft: self, published: published) unless published_version.present?
              true
            end
          end
        rescue PublishCallbackException
          return false
        end

        return true
      end

      def published_version
        PublishableMapping.for_draft(self).try(:published)
      end

      def draft_version
        PublishableMapping.for_published(self).try(:draft)
      end

    end

  end
end

ActiveRecord::Base.send(:include, WillPublish::Publishable)