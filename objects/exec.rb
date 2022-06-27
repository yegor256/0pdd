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

require 'English'
require 'open3'
require 'timeout'

#
# One command exec
#
class Exec
  # When it fails.
  class Error < StandardError
    attr_reader :code

    def initialize(code, msg)
      super(msg)
      @code = code
    end
  end

  def initialize(*rest)
    @cmd = rest.join(' ')
  end

  def run
    c = [
      'set -x',
      'set -e',
      'set -o pipefail',
      @cmd
    ].join(' && ')
    start = Time.now
    out = ''
    err = ''
    begin
      Timeout.timeout(240) do
        Open3.popen3('bash', '-c', c) do |stdin, stdout, stderr, thr|
          stdin.close
          out += stdout.read_nonblock(8) until stdout.eof?
          err = stderr.read
          code = thr.value.exitstatus
          code = 1 unless thr.value.exited?
          unless code.zero?
            raise Error.new(
              code, "#{c} [#{code}]:\n#{err}\n#{out}"
            )
          end
        end
      end
    rescue Timeout::Error => e
      raise Error.new(
        1, "\"#{c}\" took too long (over #{(Time.now - start).to_i} seconds). \
We had to terminate it: \"#{e.message}.\" \
Most likely your repository has too many files to parse. \
Try to ignore unnecessary files by using --exclude option in your .pdd file. \
More information here: https://github.com/yegor256/pdd#how-to-run:\
\n\n${out}
\n\n#{err}"
      )
    end
    out
  end
end
