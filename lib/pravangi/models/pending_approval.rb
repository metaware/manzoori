require 'active_record'

module Pravangi
  class PendingApproval < ::ActiveRecord::Base

    belongs_to :resource, polymorphic: true

    serialize :object_changes, Hash

  end
end