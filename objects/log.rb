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

require 'base64'
require 'nokogiri'
require 'aws-sdk-dynamodb'
require_relative 'dynamo'
require_relative '../version'

#
# Log.
#
class Log
  def initialize(dynamo, repo, vcs = 'github')
    @dynamo = dynamo
    # @todo #312:30min Be sure to handle the use case where projects from
    #  different vcs have the same <user/repo_name>. This will cause a conflict.
    @vcs = (vcs || 'github').downcase
    @repo = @vcs == 'github' ? repo : Base64.encode64(repo + @vcs).gsub(%r{[\s=/]+}, '')

    raise 'You need to specify your cloud VCS' unless ['github'].include?(@vcs)
  end

  def put(tag, text)
    @dynamo.put_item(
      table_name: '0pdd-events',
      item: {
        'repo' => @repo,
        'vcs' => @vcs,
        'time' => Time.now.to_i,
        'tag' => tag,
        'text' => "#{text} /#{VERSION}"
      }
    )
  end

  def get(tag)
    @dynamo.query(
      table_name: '0pdd-events',
      index_name: 'tags',
      select: 'ALL_ATTRIBUTES',
      limit: 1,
      expression_attribute_values: {
        ':r' => @repo,
        ':t' => tag
      },
      key_condition_expression: 'repo=:r and tag=:t'
    ).items[0]
  end

  def exists(tag)
    !@dynamo.query(
      table_name: '0pdd-events',
      index_name: 'tags',
      select: 'ALL_ATTRIBUTES',
      limit: 1,
      expression_attribute_values: {
        ':r' => @repo,
        ':t' => tag
      },
      key_condition_expression: 'repo=:r and tag=:t'
    ).items.empty?
  end

  def delete(time, tag)
    @dynamo.delete_item(
      table_name: '0pdd-events',
      key: {
        'repo' => @repo,
        'time' => time
      },
      expression_attribute_values: {
        ':t' => tag
      },
      condition_expression: 'tag=:t'
    )
  end

  def list(since = Time.now.to_i)
    @dynamo.query(
      table_name: '0pdd-events',
      select: 'ALL_ATTRIBUTES',
      limit: 25,
      scan_index_forward: false,
      expression_attribute_names: {
        '#time' => 'time'
      },
      expression_attribute_values: {
        ':r' => @repo,
        ':t' => since
      },
      key_condition_expression: 'repo=:r and #time<:t'
    )
  end
end
