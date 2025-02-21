# SPDX-FileCopyrightText: Copyright (c) 2016-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'json'
require 'aws-sdk-s3'
require_relative '../version'

#
# S3 storage.
#
class Storage
  def initialize(ocket, bucket, region, key, secret)
    @object = Aws::S3::Resource.new(
      region: region,
      credentials: Aws::Credentials.new(key, secret)
    ).bucket(bucket).object(ocket)
  end

  def load
    return unless @object.exists?
    data = @object.get.body
    puts "S3 #{data.size} from #{@object.bucket_name}/#{@object.key}"
    # rubocop:disable Security/MarshalLoad
    Marshal.load(data)
    # rubocop:enable Security/MarshalLoad
  end

  def save(weights)
    data = Marshal.dump(weights)
    @object.put(body: data)
    puts "S3 #{data.size} to #{@object.bucket_name}/#{@object.key}"
  end
end
