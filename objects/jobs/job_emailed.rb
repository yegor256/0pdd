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

require 'mail'

#
# Job that emails if exception occurs.
#
class JobEmailed
  def initialize(vcs, job)
    @vcs = vcs
    @job = job
  end

  def proceed
    @job.proceed
  rescue Exception => e
    yaml = @vcs.repo.config
    emails = yaml['errors'] || []
    emails << 'admin@0pdd.com'
    trace = "#{e.message}\n\n#{e.backtrace.join("\n")}"
    name = @vcs.repo.name
    repo_owner_login = repo_user_login
    repo_owner_email = user_email(repo_owner_login)
    repository_link = @vcs.repository_link
    emails.each do |email|
      mail = Mail.new do
        from '0pdd <no-reply@0pdd.com>'
        to email
        subject "#{name}: puzzles discovery problem"
        text_part do
          content_type 'text/plain; charset=UTF-8'
          body "Hey,\n\n\
There is a problem in #{repository_link}:\n\n\
#{trace}\n\n\
If you think it's our bug, please submit it to GitHub: \
https://github.com/yegor256/0pdd/issues\n\n\
Sorry,\n\
0pdd"
        end
        html_part do
          content_type 'text/html; charset=UTF-8'
          body "<html><body><p>Hey,</p>
            <p>There is a problem in
            <a href='#{repository_link}'>#{name}</a>:</p>
            <pre>#{trace}</pre>
            <p>If you think it's our bug, please submit it to
            <a href='https://github.com/yegor256/0pdd/issues'>GitHub</a>.
            Thanks.</p>
            <p>Sorry,<br/><a href='http://www.0pdd.com'>0pdd</a></p>"
        end
      end
      mail.cc = repo_owner_email if repo_owner_email
      mail.deliver!
      puts "Email sent to #{email}"
    end
    raise e
  end

  private

  def repo_user_login
    @vcs.repo.name.split('/').first
  end

  def user_email(username)
    @vcs.user(username)[:email]
  end
end
