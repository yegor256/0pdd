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

require 'aws-sdk-dynamodb'
require 'nokogiri'
require_relative '../version'
require_relative 'dynamo'

#
# Log.
#
class Log
  def initialize(aws, repo)
    @repo = repo
    @aws = aws
  end

  def put(tag, text)
    @aws.put_item(
      table_name: '0pdd-events',
      item: {
        'repo' => @repo,
        'time' => Time.now.to_i,
        'tag' => tag,
        'text' => "#{text} /#{VERSION}"
      }
    )
  end

  def get(tag)
    @aws.query(
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
    !@aws.query(
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
    @aws.delete_item(
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
    @aws.query(
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
