require 'manzoori/version'
require 'manzoori/requires_approval'
require 'manzoori/models/pending_approval'
require 'active_record'

module Manzoori  
end

ActiveSupport.on_load(:active_record) do
  include Manzoori::Model
end