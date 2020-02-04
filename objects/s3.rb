# Copyright (c) 2016-2020 Yegor Bugayenko
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

require 'aws-sdk-s3'
require 'nokogiri'
require_relative '../version'

#
# S3 storage.
#
class S3
  def initialize(ocket, bucket, region, key, secret)
    @object = Aws::S3::Resource.new(
      region: region,
      credentials: Aws::Credentials.new(key, secret)
    ).bucket(bucket).object(ocket)
  end

  def load
    Nokogiri::XML(
      if @object.exists?
        data = @object.get.body
        puts "S3 #{data.size} from #{@object.bucket_name}/#{@object.key}"
        data
      else
        puts "Empty puzzles for #{@object.bucket_name}/#{@object.key}"
        '<puzzles xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
xsi:noNamespaceSchemaLocation="http://www.0pdd.com/puzzles.xsd"/>'
      end
    )
  end

  def save(xml)
    data = xml.to_s
    @object.put(body: data)
    puts "S3 #{data.size} to #{@object.bucket_name}/#{@object.key} \
(#{xml.xpath('//puzzle').size} puzzles)"
  end
end
