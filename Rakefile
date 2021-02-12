require 'active_record'

file 'config/database.yml'

namespace :db do
  task :connect => 'config/database.yml' do |t|
    ActiveRecord::Base.establish_connection \
      YAML.load_file 'config/database.yml'
  end

  task :disconnect do
    ActiveRecord::Base.clear_all_connections!
  end

  desc 'Create the test database - no-op for sqlite'
  task :create do
  end

  desc 'Drop the test database'
  task :drop => :disconnect do
    sh 'rm test.db'
  end

  namespace :migrate do

    desc 'Run the test database migrations'
    task :up => :'db:connect' do
      if ActiveRecord.version >= Gem::Version.new('6.0.0')
        context = ActiveRecord::Migration.new.migration_context
        migrations = context.migrations
        schema_migration = context.schema_migration
      elsif ActiveRecord.version >= Gem::Version.new('5.2')
        migrations = ActiveRecord::Migration.new.migration_context.migrations
        schema_migration = nil
      else
        migrations = ActiveRecord::Migrator.migrations('db/migrate')
        schema_migration = nil
      end
      ActiveRecord::Migrator.new(:up, migrations, schema_migration).migrate
    end

    desc 'Reverse the test database migrations'
    task :down => :'db:connect' do
      migrations = if ActiveRecord.version.version >= '5.2'
        ActiveRecord::Migration.new.migration_context.migrations
      else
        ActiveRecord::Migrator.migrations('db/migrate')
      end
      ActiveRecord::Migrator.new(:down, migrations, nil).migrate
    end

    desc "Rollback database (specify steps w/ STEP=n)."
    task rollback: :'db:connect' do
      step = ENV["STEP"] ? ENV["STEP"].to_i : 1
      ActiveRecord::Base.connection.migration_context.rollback(step)
    end
  end
  task :migrate => :'migrate:up'
  task rollback: :'migrate:rollback'

  desc 'Create and configure the test database'
  task :setup => [ :create, :migrate ]

  desc 'Drop the test tables and database'
  task :teardown => [ :'migrate:down', :drop ]
end

task :migration do
  timestamp = Time.now.strftime('%Y%m%d%H%H%S')
  File.open("db/migrate/#{timestamp}_rename.rb", 'w') do |f|
    f.write <<~EOF
      class Rename < ActiveRecord::Migration[6.0]
        def change

        end
      end
    EOF
  end
end
