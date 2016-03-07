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

        serialize manzoori_options[:manzoori_history], HashWithIndifferentAccess
      end

    end

    def manzoori_history
      if manzoori_history_attribute.present?
        self.send(manzoori_history_attribute)
      else
        warn('manzoori: Please define the manzoori_history option in your model in order to use this functionality.') 
        {}
      end
    end

    def manzoori_history_attribute
      self.class.manzoori_options[:manzoori_history]
    end

    def manzoori_object_changes
      self.changes.except(*self.class.manzoori_options[:skip_attributes])
    end

    def manzoori_skipped_attributes
      Array(self.class.manzoori_options[:skip_attributes])
    end

    def manzoori_methods_to_track
      Array(self.class.manzoori_options[:tracked_methods])
    end

    def track_approval
      warn('manzoori: The record cannot be updated, because it requires approval.')
      if changed?
        original = self.clone
        changed_attributes = HashWithIndifferentAccess.new(self.changes)

        method_values = {}
        manzoori_methods_to_track.each do |meth|
          original_method_val = self.class.find(self.id).send(meth)
          current_method_val = self.send(meth)
          method_values[meth] = [original_method_val, current_method_val] if original_method_val != current_method_val
        end

        original.pending_approvals.build(
          object_changes: original.manzoori_object_changes,
          raw_object: original.to_yaml
          ).save
        self.reload

        manzoori_skipped_attributes.each do |attr|
          self[attr] = original[attr]
        end

        if manzoori_history_attribute.present?
          histories = [original.send(manzoori_history_attribute), changed_attributes.except(*manzoori_skipped_attributes), method_values]
          self.send(manzoori_history_attribute.to_s+"=", histories.inject(&:merge))  #original.manzoori_history.merge(changed_attributes.except(*manzoori_skipped_attributes))
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