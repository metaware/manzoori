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

        before_update :track_approval, if: options[:if]

        has_many :pending_approvals, 
          class_name: 'Pravangi::PendingApproval',
          as: :resource
      end

    end

    def track_approval
      warn('Pravangi: The record cannot be updated, because it requires approval.')
      if changed?
        pending_approvals.build(
          object_changes: self.changes,
          raw_object: self.reload.to_yaml
          ).save
      end
    end

    def pending_approval?
      pending_approvals.present?
    end

  end
end