# encoding: utf-8
#
# Copyright (c) 2016 Yegor Bugayenko
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

require 'json'
require 'sinatra'
require 'sass'
require 'haml'

require_relative 'version'
require_relative 'objects/config'
require_relative 'objects/job'

get '/' do
  haml :index, layout: :layout, locals: { ver: VERSION }
end

get '/version' do
  VERSION
end

get '/p' do
  'this is not implemented yet'
end

# @todo #3:20min For some reason, at the moment of this PUSH event arrival
#  the repository is not ready yet and we don't have the current version
#  of it. Let's introduce some delay or some other method, so that we
#  can wait until the repo is in proper state.
# @todo #2:30min At the moment we're not thread-safe. If two PUSH events
#  arrive at the same time we will/may have troubles with concurrent
#  modification of S3 objects and Git repository. Let's introduce some
#  queing system, which will put all requests into a pipeline and proceed
#  them one by one.
post '/hook/github' do
  request.body.rewind
  json = JSON.parse(request.body.read)
  return unless json['ref'] == 'refs/heads/master'
  name = json['repository']['full_name']
  cfg = Config.new.yaml
  unless ENV['RACK_ENV'] == 'test'
    Job.new(
      GitRepo.new(name: name, id_rsa: cfg['id_rsa']),
      S3.new(
        "#{name}.xml",
        cfg['s3']['bucket'],
        cfg['s3']['region'],
        cfg['s3']['key'],
        cfg['s3']['secret']
      ),
      GithubTickets.new(
        name,
        cfg['github']['login'],
        cfg['github']['pwd']
      )
    ).proceed
    puts "GitHub hook from #{name}"
  end
  "thanks #{name}"
end

get '/css/*.css' do
  content_type 'text/css', charset: 'utf-8'
  file = params[:splat].first
  sass file.to_sym, views: "#{settings.root}/assets/sass"
end
