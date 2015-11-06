require 'active_record'

module Manzoori
  class PendingApproval < ::ActiveRecord::Base

    belongs_to :resource, polymorphic: true
    serialize :object_changes, Hash
    before_save :skip_attributes

    default_scope { where(is_approved: false, is_rejected: false) }
    scope :changes, -> { where(change_type: 'object_changes')}
    scope :association_changes, -> { where.not(change_type: 'object_changes')}
    scope :new_added, -> { where(change_type: 'associated_added')}
    scope :deleted, -> { where(change_type: 'associated_deleted')}



    def as_object
      @object ||= YAML.load(raw_object)
    end

    def changed_object_attributes
      self.object_changes.keys
    end

    def approve_changes
      PendingApproval.transaction do
        resource.skip_approval = true
        if change_type == 'object_change'
          object_changes.each do |k,v|
            resource[k] = v[1]
          end
        elsif change_type == 'associated_added'
          resource.send(association_type.underscore.pluralize).build(YAML.load(raw_object).attributes)

        elsif change_type == 'associated_deleted'
          object = association_type.constantize.find deleted_id
          object.destroy
        end

        self.update_attribute(:is_approved, true)
        resource.save
        resource.reload
        resource.skip_approval = false
      end
    end

    def reject_changes
      self.update_attribute(:is_rejected, true)
    end

    def skip_attributes
      if self.resource.class.manzoori_options[:skip_attributes]
        object_changes.except(*self.resource.class.manzoori_options[:skip_attributes])
      end
    end

  end
end