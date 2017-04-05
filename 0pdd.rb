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

require 'haml'
require 'json'
require 'ostruct'
require 'sinatra'
require 'sass'
require 'octokit'

require_relative 'version'
require_relative 'objects/config'
require_relative 'objects/job'
require_relative 'objects/job_detached'
require_relative 'objects/job_emailed'
require_relative 'objects/job_recorded'
require_relative 'objects/git_repo'
require_relative 'objects/github_tickets'
require_relative 'objects/safe_storage'
require_relative 'objects/s3'

get '/' do
  haml :index, layout: :layout, locals: {
    ver: VERSION,
    tail: `sort /tmp/0pdd-done.txt | uniq | tail -10`.split("\n")
      .reject(&:empty?)
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
  Nokogiri::XSLT(File.read('assets/xsl/puzzles.xsl')).transform(
    storage(name).load, ['project', "'#{name}'"]
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
  cfg = Config.new.yaml
  client = Octokit::Client.new(
    login: cfg['github']['login'],
    password: cfg['github']['pwd']
  )
  last = nil
  client.notifications.each do |n|
    reason = n['reason']
    puts "GitHub notification in #{n['repository']['full_name']}: #{reason}"
    if reason == 'invitation'
      client.user_repository_invitations.each do |i|
        puts "Invitation ##{i['id']}"
        puts i
        client.accept_repository_invitation(i['id'])
      end
    end
    last = n['last_read_at']
  end
  client.mark_notifications_as_read(last_read_at: time) unless last.nil?
end

post '/hook/github' do
  request.body.rewind
  json = JSON.parse(request.body.read)
  return unless json['ref'] == 'refs/heads/master'
  name = json['repository']['full_name']
  cfg = Config.new.yaml
  unless ENV['RACK_ENV'] == 'test'
    repo = GitRepo.new(name: name, id_rsa: cfg['id_rsa'])
    JobDetached.new(
      repo,
      JobRecorded.new(
        name,
        JobEmailed.new(
          name,
          repo,
          cfg,
          Job.new(
            repo,
            storage(name),
            GithubTickets.new(
              name,
              cfg['github']['login'],
              cfg['github']['pwd'],
              repo
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
      cfg = Config.new.yaml
      S3.new(
        "#{name}.xml",
        cfg['s3']['bucket'],
        cfg['s3']['region'],
        cfg['s3']['key'],
        cfg['s3']['secret']
      )
    end
  )
end
