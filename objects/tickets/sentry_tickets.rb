# SPDX-FileCopyrightText: Copyright (c) 2016-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'mail'
require 'sentry-ruby'
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
    Sentry.capture_exception(e)
    email(e)
    raise e
  end

  def submit(puzzle)
    @tickets.submit(puzzle)
  rescue UserError => e
    puts e.message
    nil
  rescue Exception => e
    Sentry.capture_exception(e)
    email(e)
    raise e
  end

  def close(puzzle)
    @tickets.close(puzzle)
  rescue UserError => e
    puts e.message
    true
  rescue Exception => e
    Sentry.capture_exception(e)
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
