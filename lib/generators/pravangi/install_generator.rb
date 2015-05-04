require 'rails/generators'
require 'rails/generators/active_record'

module Manzoori
  class InstallGenerator < ::Rails::Generators::Base
    include ::Rails::Generators::Migration

    source_root File.expand_path('../templates', __FILE__)

    def create_migration_file
      add_pravangi_versions_migration('create_pending_approvals')
    end

    def self.next_migration_number(dirname)
      ::ActiveRecord::Generators::Base.next_migration_number(dirname)
    end

    protected
    def add_pravangi_versions_migration(template)
      migration_dir = File.expand_path('db/migrate')

      unless self.class.migration_exists?(migration_dir, template)
        migration_template "#{template}.rb", "db/migrate/#{template}.rb"
      else
        warn("ALERT: Migration already exists named '#{template}'." +
               " Please check your migrations directory before re-running")
      end
    end

  end
end