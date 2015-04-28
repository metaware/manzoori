require 'pravangi/version'
require 'pravangi/requires_approval'
require 'pravangi/models/pending_approval'
require 'active_record'

module Pravangi  
end

ActiveSupport.on_load(:active_record) do
  include Pravangi::Model
end