module WillPublish
  module Attributes
    SYSTEM_ATTRIBUTES = %w(id created_at updated_at is_published_version)

    class << self

      def filtered_attributes(attrs, only, except)
        attrs.reject!{|k,v| !only[:attributes].include?(k.to_sym) } unless only.blank? || only[:attributes].blank?
        attrs.reject!{|k,v| except[:attributes].include?(k.to_sym) } unless except.blank? || except[:attributes].blank?
        return attrs
      end

      # Return the attributes on the obj to copy, will filter through the only/except parameters,
      # and exclude system attributes(ie. id and timestamps)
      def attributes_to_copy(obj, only, except)
        attrs = obj.attributes.reject{|k,v| SYSTEM_ATTRIBUTES.include?(k) }
        filtered_attributes(attrs, only, except)
      end
      
    end
  end
end