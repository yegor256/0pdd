# Copyright (c) 2016-2025 Yegor Bugayenko
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

#
# Storage that is logged.
#
class LoggedStorage
  def initialize(origin, log)
    @origin = origin
    @log = log
  end

  def load
    @origin.load
  end

  def save(xml)
    @origin.save(xml)
    @log.put(
      "save-#{Time.now.to_i}",
      "Saved XML, puzzles:#{xml.xpath('//puzzle[@alive="true"]').size}/\
#{xml.xpath('//puzzle').size}, chars:#{xml.to_s.length}, \
date:#{xml.xpath('/*/@date')[0].text}, \
version:#{xml.xpath('/*/@version')[0].text}"
    )
  end
end
