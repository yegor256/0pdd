# Copyright (c) 2016-2023 Yegor Bugayenko
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

require_relative '../truncated'

#
# Job that posts exceptions as commit messages.
#
class JobCommitErrors
  def initialize(vcs, job)
    @vcs = vcs
    @job = job
  end

  def proceed
    @job.proceed
  rescue Exception => e
    done = @vcs.create_commit_comment(
      @vcs.repo.head_commit_hash,
      "I wasn't able to retrieve PDD puzzles from the code base and \
submit them to #{@vcs.name}. If you \
think that it's a bug on our side, please submit it to \
[yegor256/0pdd](https://github.com/yegor256/0pdd/issues):\n\n\
> #{Truncated.new(e.message.gsub(/\s/, ' '), 300)}\n\n
Please, copy and paste this stack trace to GitHub:\n\n
```\n#{e.class.name}\n#{e.message}\n#{e.backtrace.join("\n")}\n```"
    )
    puts "Comment posted about an error: #{done[:html_url]}"
    raise e
  end
end
