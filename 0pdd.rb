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

STDOUT.sync = true

require 'mail'
require 'haml'
require 'json'
require 'ostruct'
require 'sinatra'
require 'sinatra/cookies'
require 'sass'
require 'raven'
require 'octokit'
require 'tmpdir'
require 'glogin'

require_relative 'version'
require_relative 'objects/jobs/job'
require_relative 'objects/jobs/job_detached'
require_relative 'objects/jobs/job_emailed'
require_relative 'objects/jobs/job_recorded'
require_relative 'objects/jobs/job_starred'
require_relative 'objects/jobs/job_commiterrors'
require_relative 'objects/log'
require_relative 'objects/clients/github'
require_relative 'objects/user_error'
require_relative 'objects/git_repo'
require_relative 'objects/invitations/github_invitations'
require_relative 'objects/tickets/github_tickets'
require_relative 'objects/tickets/github_tagged_tickets'
require_relative 'objects/tickets/emailed_tickets'
require_relative 'objects/tickets/logged_tickets'
require_relative 'objects/tickets/commit_tickets'
require_relative 'objects/tickets/sentry_tickets'
require_relative 'objects/tickets/milestone_tickets'
require_relative 'objects/storage/safe_storage'
require_relative 'objects/storage/sync_storage'
require_relative 'objects/storage/logged_storage'
require_relative 'objects/storage/versioned_storage'
require_relative 'objects/storage/upgraded_storage'
require_relative 'objects/storage/cached_storage'
require_relative 'objects/storage/once_storage'
require_relative 'objects/storage/s3'
require_relative 'objects/dynamo'

configure do
  Haml::Options.defaults[:format] = :xhtml
  config = if ENV['RACK_ENV'] == 'test'
    {
      'testing' => true,
      'github' => {
        'token' => '--the-token--',
        'client_id' => '?',
        'client_secret' => '?'
      },
      'sentry' => '',
      's3' => {
        'region' => '?',
        'bucket' => '?',
        'key' => '?',
        'secret' => '?'
      },
      'id_rsa' => ''
    }
  else
    YAML.safe_load(File.open(File.join(File.dirname(__FILE__), 'config.yml')))
  end
  if ENV['RACK_ENV'] != 'test'
    Raven.configure do |c|
      c.dsn = config['sentry']
      c.release = VERSION
    end
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
  set :server_settings, timeout: 25
  set :github, GithubClient.new(config)
  set :dynamo, Dynamo.new(config).aws
  set :glogin, GLogin::Auth.new(
    config['github']['client_id'],
    config['github']['client_secret'],
    'https://www.0pdd.com/github-callback'
  )
  set :ruby_version, Exec.new('ruby -e "print RUBY_VERSION"').run
  set :git_version, Exec.new('git --version | cut -d" " -f 3').run
  set :temp_dir, Dir.mktmpdir('0pdd')
end

before '/*' do
  @locals = {
    ver: VERSION,
    login_link: settings.glogin.login_uri
  }
  if cookies[:glogin]
    begin
      @locals[:user] = GLogin::Cookie::Closed.new(
        cookies[:glogin],
        settings.config['github']['encryption_secret']
      ).to_user
    rescue OpenSSL::Cipher::CipherError
      @locals.delete(:user)
    end
  end
end

get '/github-callback' do
  code = params[:code]
  redirect('/') if code.nil?
  cookies[:glogin] = GLogin::Cookie::Open.new(
    settings.glogin.user(code),
    settings.config['github']['encryption_secret']
  ).to_s
  redirect to('/')
end

get '/logout' do
  cookies.delete(:glogin)
  redirect to('/')
end

get '/' do
  haml :index, layout: :layout, locals: merged(
    title: '0pdd',
    ruby_version: settings.ruby_version,
    git_version: settings.git_version,
    remaining: settings.github.rate_limit.remaining,
    tail: Exec.new(
      "(sort /tmp/0pdd-done.txt 2>/dev/null || echo '')\
      | uniq\
      | tail -10"
    ).run.split("\n").reject(&:empty?)
  )
end

get '/robots.txt' do
  'User-agent: *
Disallow: /snapshot'
end

get '/version' do
  VERSION
end

get '/invitation' do
  repo = repo_name(params[:repo])
  ghi = GithubInvitations.new(settings.github)
  invitations = ghi.accept_single_invitation(repo)
  return invitations.join('\n') unless invitations.empty?
  "Could not find invitation for @#{repo}. It is either invitation already
   accepted OR 0pdd is not added as a collaborator"
end

get '/p' do
  name = repo_name(params[:name])
  xml = storage(name).load
  Nokogiri::XSLT(File.read('assets/xsl/puzzles.xsl')).transform(
    xml,
    [
      'version', "'#{VERSION}'",
      'project', "'#{name}'",
      'length', xml.to_s.length.to_s
    ]
  ).to_s
end

# @todo #41:30min Let's add GZIP compression to this output, since
#  most XML files are rather big and it would be beneficial to see
#  them compressed in the browser.
get '/xml' do
  content_type 'text/xml'
  storage(repo_name(params[:name])).load.to_s
end

get '/log' do
  repo = repo_name(params[:name])
  haml :log, layout: :layout, locals: merged(
    title: repo,
    repo: repo,
    log: Log.new(settings.dynamo, repo),
    since: params[:since] ? params[:since].to_i : Time.now.to_i + 1
  )
end

get '/snapshot' do
  content_type 'text/xml'
  name = repo_name(params[:name])
  master = params[:branch]
  uri = "git@github.com:#{name}.git"
  begin
    repo = GitRepo.new(
      uri: uri,
      name: name,
      id_rsa: settings.config['id_rsa'],
      dir: settings.temp_dir,
      master: master || 'master'
    )
    repo.push
    xml = repo.xml
    xml.xpath('//processing-instruction("xml-stylesheet")').remove
    xml.to_s
  rescue StandardError
    error 400, "Could not get snapshot for #{name}"
  end
end

get '/log-item' do
  repo = repo_name(params[:repo])
  tag = params[:tag]
  error 404 if tag.nil?
  log = Log.new(settings.dynamo, repo)
  error 404 unless log.exists(tag)
  haml :item, layout: :layout, locals: merged(
    title: tag,
    repo: repo,
    item: log.get(tag)
  )
end

get '/log-delete' do
  redirect '/' if @locals[:user].nil? || @locals[:user][:login] != 'yegor256'
  repo = repo_name(params[:name])
  Log.new(settings.dynamo, repo).delete(params[:time].to_i, params[:tag])
  redirect "/log?name=#{repo}"
end

get '/svg' do
  response.headers['Cache-Control'] = 'no-cache, private'
  content_type 'image/svg+xml'
  name = repo_name(params[:name])
  Nokogiri::XSLT(File.read('assets/xsl/svg.xsl')).transform(
    storage(name).load, ['project', "'#{name}'"]
  ).to_s
end

get '/ping-github' do
  content_type 'text/plain'
  gh = settings.github
  return if gh.rate_limit.remaining < 1000
  invitations = GithubInvitations.new(gh)
  invitations.accept
  invitations.accept_orgs
  gh.notifications.map do |n|
    reason = n['reason']
    repo = n['repository']['full_name']
    puts "GitHub notification in #{repo}: #{reason} #{n['updated_at']} #{n['subject']['type']}"
    if reason == 'mention'
      issue = n['subject']['url'].gsub(%r{^.+/issues/}, '').to_i
      comment = n['subject']['latest_comment_url'].gsub(%r{^.+/comments/}, '').to_i
      begin
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
      rescue Octokit::NotFound
        next
      end
    end
    gh.mark_notifications_as_read(last_read_at: n['last_read_at'])
    "#{repo}: #{reason}"
  end.join("\n") + "\n"
end

get '/hook/github' do
  'This URL expects POST requests from GitHub
  WebHook: https://developer.github.com/webhooks/'
end

post '/hook/github' do
  request.body.rewind
  json = JSON.parse(
    case request.content_type
    when 'application/x-www-form-urlencoded'
      params[:payload]
    when 'application/json'
      request.body.read
    else
      raise "Invalid content-type: \"#{request.content_type}\""
    end
  )
  unless json['repository'] && json['repository']['full_name'] &&
    json['ref'] == "refs/heads/#{json['repository']['default_branch'] || 'master'}" &&
    json['head_commit'] && json['head_commit']['id']
    return 'Thanks'
  end
  name = repo_name(json['repository']['full_name'])
  unless ENV['RACK_ENV'] == 'test'
    process_request(json)
    puts "GitHub hook from #{name}"
  end
  "Thanks #{name}"
end

get '/css/*.css' do
  content_type 'text/css', charset: 'utf-8'
  file = params[:splat].first
  sass file.to_sym, views: "#{settings.root}/assets/sass"
end

get '/puzzles.xsd' do
  content_type 'application/xml', charset: 'utf-8'
  File.read('assets/xsd/puzzles.xsd')
end

not_found do
  status 404
  content_type 'text/html', charset: 'utf-8'
  haml :not_found, layout: :layout, locals: merged(
    title: 'Page not found'
  )
end

error do
  status 503
  e = env['sinatra.error']
  Raven.capture_exception(e) unless e.is_a?(UserError)
  haml(
    :error,
    layout: :layout,
    locals: merged(
      title: 'error',
      error: "#{e.message}\n\t#{e.backtrace.join("\n\t")}"
    )
  )
end

private

def repo_name(name)
  error 404 if name.nil?
  error 404 unless name =~ %r{^[a-zA-Z0-9\-_]+/[a-zA-Z0-9\-_.]+$}
  name.strip
end

def merged(hash)
  out = @locals.merge(hash)
  out[:local_assigns] = out
  out
end

# @todo #41:30min Make this vcs independent. Move to github vsc object.
def repo(json)
  uri = json['repository']['ssh_url'] || json['repository']['url']
  name = json['repository']['full_name']
  default_branch = json['repository']['master_branch']
  head_commit_hash = json['head_commit']['id']
  begin
    settings.github.repository(name)['default_branch']
  rescue Octokit::InvalidRepository => e
    raise "Repository #{name} is not available: #{e.message}"
  rescue Octokit::NotFound
    error 400
  end
  GitRepo.new(
    uri: uri,
    name: name,
    id_rsa: @config['id_rsa'],
    master: default_branch,
    head_commit_hash: head_commit_hash
  )
end

def storage(repo)
  SyncStorage.new(
    UpgradedStorage.new(
      SafeStorage.new(
        OnceStorage.new(
          CachedStorage.new(
            VersionedStorage.new(
              if ENV['RACK_ENV'] == 'test'
                FakeStorage.new
              else
                LoggedStorage.new(
                  S3.new(
                    "#{repo}.xml",
                    settings.config['s3']['bucket'],
                    settings.config['s3']['region'],
                    settings.config['s3']['key'],
                    settings.config['s3']['secret']
                  ),
                  Log.new(settings.dynamo, repo)
                )
              end,
              VERSION
            ),
            File.join('/tmp/0pdd-xml-cache', repo)
          )
        )
      ),
      VERSION
    )
  )
end

def process_request(json)
  repo = repo(json)
  JobDetached.new(
    repo,
    JobCommitErrors.new(
      name,
      settings.github,
      json['head_commit']['id'],
      JobEmailed.new(
        name,
        settings.github,
        repo,
        JobRecorded.new(
          name,
          settings.github,
          JobStarred.new(
            name,
            settings.github,
            Job.new(
              repo,
              storage(name),
              SentryTickets.new(
                EmailedTickets.new(
                  name,
                  CommitTickets.new(
                    name,
                    repo,
                    settings.github,
                    json['head_commit']['id'],
                    GithubTaggedTickets.new(
                      name,
                      settings.github,
                      repo,
                      LoggedTickets.new(
                        Log.new(settings.dynamo, name),
                        name,
                        MilestoneTickets.new(
                          name,
                          repo,
                          settings.github,
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
            )
          )
        )
      )
    )
  ).proceed
end
