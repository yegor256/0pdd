# SPDX-FileCopyrightText: Copyright (c) 2016-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

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
        Open3.popen3('bash', '-c', c) do |stdin, stdout, stderr, thread|
          stdin.close
          out += stdout.read_nonblock(8) until stdout.eof?
          err = stderr.read
          code = thread.value.exitstatus
          code = 1 unless thread.value.exited?
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
    puts "+ #{c}"
    out
  end
end
