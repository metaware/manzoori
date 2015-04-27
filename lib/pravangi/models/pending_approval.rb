require 'active_record'

module Pravangi
  class PendingApproval < ::ActiveRecord::Base

    belongs_to :resource, polymorphic: true
    serialize :object_changes, Hash

    def as_object
      @object ||= YAML.load(raw_object)
    end

    def commit
      resource.skip_approval = true
      object_changes.each do |k,v|
        resource[k] = v[1]
      end
      resource.save
      resource.reload
    end

  end
end