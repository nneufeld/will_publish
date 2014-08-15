module WillPublish
  module Publishable

    SYSTEM_ATTRIBUTES = %w(id created_at updated_at is_published_version)

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

        extend PublishableClassMethods
        include InstanceMethods
      end

    end

    module PublishableClassMethods
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
              published_version.attributes = attributes_to_copy(self, self.only, self.except).merge(is_published_version: true)
              published_version.save!

              copy_associations(self, published_version, self.only, self.except)

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

      # Given assoc_name of :steps and current_assoc_filters of { associations: [:comments, {steps: { attributes: [:like_count], associations: [:comments] }}] }
      # will return { attributes: [:like_count], associations: [:comments] }
      # used to pass along the only/except filters when recursively copying associations
      def assoc_filters_to_pass_on(current_assoc_filters, assoc_name)
        return nil if current_assoc_filters.blank? || current_assoc_filters[:associations].blank?
        filters = current_assoc_filters[:associations].select{|a| a.is_a?(Hash) && a.keys.first == assoc_name }.collect{|e| e[assoc_name] }.flatten
        return filters.first if filters.present?
      end

      # Will filter the associations through the only/except parameters
      def filtered_associations(assocs, only, except)
        assocs.reject!{|a| !only[:associations].include?(a.name) } unless only.blank? || only[:associations].blank?
        assocs.reject!{|a| except[:associations].include?(a.name) } unless except.blank? || except[:associations].blank?
        return assocs
      end

      # Return the associations on the klass that should be copied, will filter through
      # the only/except parameters and exclude belongs_to and has_many_through associations
      def associations_to_copy(klass, only, except)
        assocs = klass.reflect_on_all_associations
        assocs.reject!{|a| a.macro == :belongs_to || a.class == ActiveRecord::Reflection::ThroughReflection || !klass.new.respond_to?(a.name) }
        filtered_associations(assocs, only, except)
      end

      def filtered_attributes(attrs, only, except)
        attrs.reject!{|k,v| !only[:attributes].include?(k.to_sym) } unless only.blank? || only[:attributes].blank?
        attrs.reject!{|k,v| except[:attributes].include?(k.to_sym) } unless except.blank? || except[:attributes].blank?
        return attrs
      end

      # Return the attributes on the obj to copy, will filter through the only/except parameters,
      # and exclude system attributes(ie. id and timestamps)
      def attributes_to_copy(obj, only, except)
        attrs = obj.attributes.reject{|k,v| WillPublish::Publishable::SYSTEM_ATTRIBUTES.include?(k) }
        filtered_attributes(attrs, only, except)
      end

      # Will copy the object's associations, applying the only/except parameters
      def copy_associations(from, to, only, except)
        assocs = associations_to_copy(from.class, only, except)
        
        assocs.each do |assoc|
          if assoc.macro == :has_and_belongs_to_many
            copy_habtm_association(from, to, assoc)
          elsif assoc.macro == :has_many || assoc.macro == :has_one
            copy_hm_or_ho_association(from, to, assoc, assoc_filters_to_pass_on(only, assoc.name), assoc_filters_to_pass_on(except, assoc.name))
          end
        end
      end

      def copy_habtm_association(from, to, assoc)
        to.send(assoc.name).clear
        to.send(assoc.name) << from.send(assoc.name)
      end

      # Is executed recursively to copy the object's has_one and has_many assoications, filtering based on only/except
      def copy_hm_or_ho_association(from, to, assoc, only, except)
        # delete published objects for which a draft no longer exists
        [*to.send(assoc.name)].each do |to_rel|
          from_mapping = WillPublish::PublishableMapping.for_published(to_rel)
          from_rel = from_mapping.try(:draft)
          
          unless from_rel.present?
            to_rel.destroy
            from_mapping.destroy if from_mapping.present?
          end
        end

        [*from.send(assoc.name)].each do |from_rel|
          to_rel = WillPublish::PublishableMapping.for_draft(from_rel).try(:published)
          create_mapping = false
          # create published objects for draft objects that don't have a published version yet
          if to_rel.nil?
            to_rel = from_rel.class.send(:new, attributes_to_copy(from_rel, only, except))
            create_mapping = true
          else # update the published version for draft objects that already have a published version
            to_rel.attributes = attributes_to_copy(from_rel, only, except)
          end

          to_rel[assoc.foreign_key] = to.id
          to_rel.save!

          WillPublish::PublishableMapping.create(draft: from_rel, published: to_rel) if create_mapping

          copy_associations(from_rel, to_rel, only, except)
        end
      end

    end

  end
end

ActiveRecord::Base.send(:include, WillPublish::Publishable)