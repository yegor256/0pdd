# SPDX-FileCopyrightText: Copyright (c) 2016-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'rubygems'
require 'rake'
require 'rake/clean'
require_relative 'objects/dynamo'

ENV['RACK_ENV'] = 'test'

task default: %i[clean test rubocop xcop]

require 'rake/testtask'
desc 'Run all unit tests'
Rake::TestTask.new(test: :dynamo) do |test|
  Rake::Cleaner.cleanup_files(['coverage'])
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = false
  test.warning = false
end

require 'rubocop/rake_task'
desc 'Run RuboCop on all directories'
RuboCop::RakeTask.new(:rubocop) do |task|
  task.fail_on_error = true
end

require 'xcop/rake_task'
desc 'Validate all XML/XSL/XSD/HTML files for formatting'
Xcop::RakeTask.new :xcop do |task|
  task.includes = ['**/*.xml', '**/*.xsl', '**/*.xsd', '**/*.html']
  task.excludes = ['target/**/*', 'coverage/**/*', 'vendor/**/*']
end

desc 'Start DynamoDB Local server'
task :dynamo do
  FileUtils.rm_rf('dynamodb-local/target')
  pid = Process.spawn('mvn', 'install', '--quiet', chdir: 'dynamodb-local')
  at_exit do
    `kill -TERM #{pid}`
    puts "DynamoDB Local killed in PID #{pid}"
  end
  begin
    status = Dynamo.new.aws.describe_table(
      table_name: '0pdd-events'
    )[:table][:table_status]
    puts "DynamoDB Local table: #{status}"
  rescue Exception => e
    puts e.message
    sleep(5)
    retry
  end
  puts "DynamoDB Local is running in PID #{pid}"
end

desc 'Sleep endlessly after the start of DynamoDB Local server'
task :sleep do
  loop do
    sleep(5)
    puts 'Still alive...'
  end
end

desc 'Run website'
task run: :dynamo do
  `rerun -b "RACK_ENV=test rackup"`
end
