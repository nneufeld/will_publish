module WillPublish
  module Publishable

    class PublishCallbackException < StandardError; end

    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods

      def will_publish
        # add support for callbacks
        include ActiveSupport::Callbacks
        define_callbacks :publish, terminator: ->(target, result) { result == false }
        extend CallbackMethods

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
              published_version = self.published || self.class.new
              published_version.attributes = attributes_to_copy.merge(is_published_version: true)
              published_version.save!
              WillPublish::PublishableMapping.create!(draft: self, published: published_version) unless published.present?
              true
            end
          end
        rescue PublishCallbackException
          return false
        end

        return true
      end

      def published
        WillPublish::PublishableMapping.for_draft(self).try(:published)
      end

      def draft
        WillPublish::PublishableMapping.for_published(self).try(:draft)
      end

      private

      def attributes_to_copy
        self.attributes.reject{|k,v| self.class.attributes_to_reject.include?(k) }
      end

    end

  end
end

ActiveRecord::Base.send(:include, WillPublish::Publishable)