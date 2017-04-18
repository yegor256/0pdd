# encoding: utf-8
#
# Copyright (c) 2016-2017 Yegor Bugayenko
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

require 'mail'
require 'haml'
require 'json'
require 'ostruct'
require 'sinatra'
require 'sass'
require 'octokit'
require 'tmpdir'

require_relative 'version'
require_relative 'objects/job'
require_relative 'objects/job_detached'
require_relative 'objects/job_emailed'
require_relative 'objects/job_recorded'
require_relative 'objects/job_starred'
require_relative 'objects/job_commiterrors'
require_relative 'objects/git_repo'
require_relative 'objects/github_tickets'
require_relative 'objects/emailed_tickets'
require_relative 'objects/safe_storage'
require_relative 'objects/s3'

configure do
  config = if ENV['RACK_ENV'] == 'test'
    {
      'github' => {
        'login' => '0pdd',
        'pwd' => '--the-secret--'
      },
      's3' => {
        'region' => '?',
        'bucket' => '?',
        'key' => '?',
        'secret' => '?'
      },
      'id_rsa' => ''
    }
  else
    YAML.load(File.open(File.join(File.dirname(__FILE__), 'config.yml')))
  end
  set :config, config
  if config['smtp']
    Mail.defaults do
      delivery_method(
        :smtp,
        address: config['smtp']['host'],
        port: config['smtp']['port'],
        user_name: config['smtp']['user'],
        password: config['smtp']['password'],
        domain: '0pdd.com',
        enable_starttls_auto: true
      )
    end
  end
  set :github, if ENV['RACK_ENV'] == 'test'
    require_relative 'test/test__helper'
    FakeGithub.new
  else
    Octokit::Client.new(
      login: settings.config['github']['login'],
      password: settings.config['github']['pwd']
    )
  end
  set :ruby_version, Exec.new('ruby -e "print RUBY_VERSION"').run
  set :git_version, Exec.new('git --version | cut -d" " -f 3').run
  set :temp_dir, Dir.mktmpdir('0pdd')
end

get '/' do
  haml :index, layout: :layout, locals: {
    ver: VERSION,
    ruby_version: settings.ruby_version,
    git_version: settings.git_version,
    tail: Exec.new(
      "(sort /tmp/0pdd-done.txt 2>/dev/null || echo '')\
      | uniq\
      | tail -10"
    ).run.split("\n").reject(&:empty?)
  }
end

get '/robots.txt' do
  ''
end

get '/version' do
  VERSION
end

get '/p' do
  name = params[:name]
  xml = storage(name).load
  Nokogiri::XSLT(File.read('assets/xsl/puzzles.xsl')).transform(
    xml, ['project', "'#{name}'", 'length', xml.to_s.length.to_s]
  ).to_s
end

# @todo #41:30min Let's add GZIP compression to this output, since
#  most XML files are rather big and it would be beneficial to see
#  them compressed in the browser.
get '/xml' do
  content_type 'text/xml'
  storage(params[:name]).load.to_s
end

get '/svg' do
  response.headers['Cache-Control'] = 'no-cache, private'
  content_type 'image/svg+xml'
  name = params[:name]
  Nokogiri::XSLT(File.read('assets/xsl/svg.xsl')).transform(
    storage(name).load, ['project', "'#{name}'"]
  ).to_s
end

get '/ping-github' do
  content_type 'text/plain'
  gh = settings.github
  gh.notifications.map do |n|
    reason = n['reason']
    repo = n['repository']['full_name']
    puts "GitHub notification in #{repo}: #{reason}"
    if reason == 'invitation'
      gh.user_repository_invitations.each do |i|
        gh.accept_repository_invitation(i['id'])
      end
      puts "Invitation accepted to #{repo}"
    end
    if reason == 'mention'
      issue = n['subject']['url'].gsub(%r{^.+/issues/}, '')
      comment = n['subject']['latest_comment_url'].gsub(%r{^.+/comments/}, '')
      json = gh.issue_comment(repo, comment)
      body = json['body']
      if body.start_with?("@#{gh.login}") && json['user']['login'] != gh.login
        gh.add_comment(
          repo,
          issue,
          "> #{body.gsub(/\s+/, ' ').gsub(/^(.{100,}?).*$/m, '\1...')}\n\n\
I see you're talking to me, but I can't reply since I'm not a chat bot."
        )
        puts "Replied to #{repo}##{issue}"
      end
    end
    gh.mark_notifications_as_read(last_read_at: n['last_read_at'])
    "#{repo}: #{reason}"
  end.join("\n") + "\n"
end

post '/hook/github' do
  request.body.rewind
  json = JSON.parse(request.body.read)
  return unless json['ref'] == 'refs/heads/master'
  name = json['repository']['full_name']
  unless ENV['RACK_ENV'] == 'test'
    repo = GitRepo.new(
      name: name,
      id_rsa: settings.config['id_rsa'],
      dir: settings.temp_dir
    )
    JobDetached.new(
      repo,
      JobCommitErrors.new(
        name,
        settings.github,
        json['head_commit']['id'],
        JobEmailed.new(
          name,
          repo,
          JobRecorded.new(
            name,
            JobStarred.new(
              name,
              settings.github,
              Job.new(
                repo,
                storage(name),
                EmailedTickets.new(
                  name,
                  GithubTickets.new(
                    name,
                    settings.github,
                    repo
                  )
                )
              )
            )
          )
        )
      )
    ).proceed
    puts "GitHub hook from #{name}"
  end
  "Thanks #{name}"
end

get '/css/*.css' do
  content_type 'text/css', charset: 'utf-8'
  file = params[:splat].first
  sass file.to_sym, views: "#{settings.root}/assets/sass"
end

not_found do
  status 404
  haml :not_found, layout: :layout, locals: { ver: VERSION }
end

error do
  status 503
  e = env['sinatra.error']
  haml(
    :error,
    layout: :layout,
    locals: {
      ver: VERSION,
      error: "#{e.message}\n\t#{e.backtrace.join("\n\t")}"
    }
  )
end

private

def storage(name)
  SafeStorage.new(
    if ENV['RACK_ENV'] == 'test'
      FakeStorage.new
    else
      S3.new(
        "#{name}.xml",
        settings.config['s3']['bucket'],
        settings.config['s3']['region'],
        settings.config['s3']['key'],
        settings.config['s3']['secret']
      )
    end
  )
end
