require 'active_support'

module Pravangi
  module Model
    
    extend ::ActiveSupport::Concern

    included do |base|
      base.send :extend, ClassMethods
    end

    class_methods do 
      
      def requires_approval(options = {})
        class_attribute :pravangi_options
        self.pravangi_options = options.dup

        attr_accessor :skip_approval

        class_eval do 
          def should_track_approval?
            self.send(self.class.pravangi_options[:if]) && !skip_approval
          end
        end

        before_update :track_approval, if: :should_track_approval?

        has_many :pending_approvals, 
          lambda { order('id ASC') },
          class_name: 'Pravangi::PendingApproval',
          as: :resource
      end

    end

    def pravangi_object_changes
      self.changes.except(*self.class.pravangi_options[:skip_attributes])
    end

    def track_approval
      warn('Pravangi: The record cannot be updated, because it requires approval.')
      if changed?
        original = self.clone
        original.pending_approvals.build(
          object_changes: original.pravangi_object_changes,
          raw_object: original.to_yaml
          ).save
        self.reload

        skip_attributes = Array(self.class.pravangi_options[:skip_attributes])
        skip_attributes.each do |attr|
          self[attr] = original[attr]
        end
      end
    end

    def pending_approval?
      pending_approvals.present?
    end

  end
end