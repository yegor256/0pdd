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
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

require 'test/unit'
require 'mail'

class CredentialsTest < Test::Unit::TestCase
  def test_sends_email_via_smtp
    cfg = config
    Mail.defaults do
      delivery_method(
        :smtp,
        address: cfg['smtp']['host'],
        port: cfg['smtp']['port'],
        user_name: cfg['smtp']['user'],
        password: cfg['smtp']['password'],
        domain: '0pdd.com',
        enable_starttls_auto: true
      )
    end
    mail = Mail.new do
      from '0pdd <no-reply@0pdd.com>'
      to 'admin@0pdd.com'
      subject 'Test email, ignore it'
      text_part do
        content_type 'text/plain; charset=UTF-8'
        body 'It it a test email, ignore it.'
      end
    end
    mail.deliver!
  end

  private

  def config
    file = File.join(File.dirname(__FILE__), '../config.yml')
    omit unless File.exist?(file)
    YAML.safe_load(File.open(file))
  end
end
