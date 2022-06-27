# Copyright (c) 2016-2022 Yegor Bugayenko
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the 'Software'), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

require 'rubygems'
require 'rake'
require 'rdoc'
require 'rake/clean'
require_relative 'objects/dynamo'

ENV['RACK_ENV'] = 'test'

task default: %i[check_outdated_gems clean test rubocop xcop copyright]

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
  task.requires << 'rubocop-rspec'
end

require 'xcop/rake_task'
desc 'Validate all XML/XSL/XSD/HTML files for formatting'
Xcop::RakeTask.new :xcop do |task|
  task.license = 'LICENSE.txt'
  task.includes = ['**/*.xml', '**/*.xsl', '**/*.xsd', '**/*.html']
  task.excludes = ['target/**/*', 'coverage/**/*']
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

task run: :dynamo do
  `rerun -b "RACK_ENV=test rackup"`
end

task :copyright do
  sh "grep -q -r '#{Date.today.strftime('%Y')}' \
    --include '*.rb' \
    --include '*.txt' \
    --include 'Rakefile' \
    ."
end

task :check_outdated_gems do
  sh 'bundle outdated' do |ok, _|
    puts 'Some dependencies are outdated' unless ok
  end
end
