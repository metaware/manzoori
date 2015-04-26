module Pravangi
  class PendingApproval < ::ActiveRecord::Base

    belongs_to :resource, polymorphic: true

  end
end