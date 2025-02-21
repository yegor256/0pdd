# SPDX-FileCopyrightText: Copyright (c) 2016-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'aws-sdk-s3'
require 'nokogiri'
require_relative '../../version'

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
