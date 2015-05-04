require 'active_support'

module Manzoori
  module Model
    
    extend ::ActiveSupport::Concern

    included do |base|
      base.send :extend, ClassMethods
    end

    class_methods do 
      
      def requires_approval(options = {})
        class_attribute :manzoori_options
        self.manzoori_options = options.dup

        attr_accessor :skip_approval

        class_eval do 
          def should_track_approval?
            self.send(self.class.manzoori_options[:if]) && !skip_approval
          end
        end

        before_update :track_approval, if: :should_track_approval?

        has_many :pending_approvals, 
          lambda { order('id ASC') },
          class_name: 'Manzoori::PendingApproval',
          as: :resource
      end

    end

    def manzoori_object_changes
      self.changes.except(*self.class.manzoori_options[:skip_attributes])
    end

    def track_approval
      warn('manzoori: The record cannot be updated, because it requires approval.')
      if changed?
        original = self.clone
        original.pending_approvals.build(
          object_changes: original.manzoori_object_changes,
          raw_object: original.to_yaml
          ).save
        self.reload

        skip_attributes = Array(self.class.manzoori_options[:skip_attributes])
        skip_attributes.each do |attr|
          self[attr] = original[attr]
        end
      end
    end

    def pending_approval?
      pending_approvals.present?
    end

    def approve_pending_changes
      self.pending_approvals.each(&:approve_changes)
      self.touch
      self.reload
    end

    def reject_pending_changes
      self.pending_approvals.each(&:reject_changes)
      self.touch
      self.reload
    end

  end
end