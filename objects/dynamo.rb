# SPDX-FileCopyrightText: Copyright (c) 2016-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'yaml'
require 'aws-sdk-dynamodb'

#
# Dynamo client
#
class Dynamo
  def initialize(config = {})
    @config = config
  end

  def aws
    Aws::DynamoDB::Client.new(
      if ENV['RACK_ENV'] == 'test'
        cfg = File.join(Dir.pwd, 'dynamodb-local/target/dynamo.yml')
        raise 'Test config is absent' unless File.exist?(cfg)
        yaml = YAML.safe_load(File.open(cfg))
        {
          region: 'us-east-1',
          endpoint: "http://localhost:#{yaml['port']}",
          access_key_id: yaml['key'],
          secret_access_key: yaml['secret'],
          http_open_timeout: 5,
          http_read_timeout: 5
        }
      else
        {
          region: @config['dynamo']['region'],
          access_key_id: @config['dynamo']['key'],
          secret_access_key: @config['dynamo']['secret']
        }
      end
    )
  end
end
