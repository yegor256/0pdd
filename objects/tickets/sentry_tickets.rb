# Copyright (c) 2016-2021 Yegor Bugayenko
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
require 'raven'
require_relative '../user_error'
require_relative '../truncated'

#
# Tickets that report to Sentry.
#
class SentryTickets
  def initialize(tickets)
    @tickets = tickets
  end

  def notify(issue, message)
    @tickets.notify(issue, message)
  rescue UserError => e
    puts e.message
  rescue Exception => e
    Raven.capture_exception(e)
    email(e)
    raise e
  end

  def submit(puzzle)
    @tickets.submit(puzzle)
  rescue UserError => e
    puts e.message
    nil
  rescue Exception => e
    Raven.capture_exception(e)
    email(e)
    raise e
  end

  def close(puzzle)
    @tickets.close(puzzle)
  rescue UserError => e
    puts e.message
    true
  rescue Exception => e
    Raven.capture_exception(e)
    email(e)
    raise e
  end

  private

  def email(e)
    mail = Mail.new do
      from '0pdd <no-reply@0pdd.com>'
      to 'admin@0pdd.com'
      subject Truncated.new(e.message).to_s
      text_part do
        content_type 'text/plain; charset=UTF-8'
        body "Hi,\n\n\
#{e.message}\n\n
#{e.backtrace.join("\n")}\n\n
Thanks,\n\
0pdd"
      end
      html_part do
        content_type 'text/html; charset=UTF-8'
        body "<html><body><p>Hi,</p>
        <pre>#{e.message}\n\n#{e.backtrace.join("\n")}</pre>
        </body></html>"
      end
    end
    mail.deliver!
  end
end
