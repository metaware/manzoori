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

        cattr_accessor :skip_approval

        class_eval do 
          def should_track_approval?
            self.send(self.class.manzoori_options[:if]) && !skip_approval
          end
        end

        before_update :track_approval, if: :should_track_approval?

        associations = Hash(self.manzoori_options[:associations])
        associations.each do |association, options|
          klass = self.new.send(association).class_name.safe_constantize
          klass.send(:cattr_accessor, :associated_to)
          klass.associated_to = options[:belongs_to] || self.class_name.underscore
          klass.send(:before_create,
                     lambda {|object|
                       return true if object.send(associated_to).skip_approval
                       object.send(associated_to).pending_approvals.build(
                         raw_object: object.to_yaml,
                         change_type: 'associated_added',
                         association_type: object.class.to_s
                       ).save
                       return false;
                     })

          klass.send(:after_destroy,
                     lambda {|object|
                       return true if object.send(associated_to).skip_approval
                       copy = object.dup
                       copy.send(associated_to).skip_approval = true
                       copy.save
                       copy.send(associated_to).skip_approval = false
                       product = object.send(associated_to)
                       product.pending_approvals << Manzoori::PendingApproval.new(
                         raw_object: copy.to_yaml,
                         change_type: 'associated_deleted',
                         association_type: copy.class.to_s,
                         deleted_id: copy.id
                       )
                       product.save
                     })
        end
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
          raw_object: original.to_yaml,
          change_type: 'object_changes'
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