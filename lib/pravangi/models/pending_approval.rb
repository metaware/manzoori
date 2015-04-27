require 'active_record'

module Pravangi
  class PendingApproval < ::ActiveRecord::Base

    belongs_to :resource, polymorphic: true
    serialize :object_changes, Hash
    before_save :skip_attributes

    default_scope { where(is_approved: false, is_rejected: false) }

    def as_object
      @object ||= YAML.load(raw_object)
    end

    def changed_object_attributes
      self.object_changes.keys
    end

    def approve_changes
      PendingApproval.transaction do
        resource.skip_approval = true
        object_changes.each do |k,v|
          resource[k] = v[1]
        end
        self.update_attribute(:is_approved, true)
        resource.save
        resource.reload
      end
    end

    def reject_changes
      self.update_attribute(:is_rejected, true)
    end

    def skip_attributes
      if self.resource.class.pravangi_options[:skip_attributes]
        object_changes.except(*self.resource.class.pravangi_options[:skip_attributes])
      end
    end

  end
end