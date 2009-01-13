# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require(File.join(File.dirname(__FILE__), 'config', 'boot'))

require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'

require 'tasks/rails'

desc "Clean up public downloads if greater than threshold"
task :clean_up do
  MAX_DURATION = 20 * 60
  files = Dir[ "#{File.join( RAILS_ROOT, 'public', 'download' )}/*" ]
  files.each do |file|
    if Time.now - File.mtime( file ) > MAX_DURATION
      FileUtils.rm( file )
    end
  end
end

desc "Setup necessary public directories"
task :make_dirs do
  dirs = [
    File.join( RAILS_ROOT, 'public', 'tmp' ),
    File.join( RAILS_ROOT, 'public', 'download' )
  ]

  dirs.each do |dir|
    if File.exist?( dir )
      if not File.directory?( dir )
        FileUtils.rm( dir )
        FileUtils.mkdir( dir )
      end
    else
      FileUtils.mkdir( dir )
    end
  end
end
