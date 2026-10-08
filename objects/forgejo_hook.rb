# SPDX-FileCopyrightText: Copyright (c) 2016-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'json'
require 'openssl'
require 'rack/utils'
require_relative 'vcs/forgejo'

# Authenticate before parsing or making requests. Neither the API nor clone
# destination is taken from the webhook's untrusted URL fields.
class ForgejoHook
  # A safe HTTP status/message for rejected webhook deliveries.
  class Rejected < StandardError
    attr_reader :status

    def initialize(status, message)
      @status = status
      super(message)
    end
  end

  def initialize(config)
    @config = config
  end

  def repository(host, name, body, headers)
    config = @config.fetch(host) { raise Rejected.new(404, 'Unknown Forgejo host') }
    secret = config.fetch('repositories', {}).fetch(name) do
      raise Rejected.new(404, 'Unknown Forgejo repository')
    end.to_s
    raise Rejected.new(503, 'Forgejo webhook secret is not configured') if secret.empty?
    digest = OpenSSL::HMAC.hexdigest('SHA256', secret, body)
    unless Rack::Utils.secure_compare(digest, headers['HTTP_X_FORGEJO_SIGNATURE'].to_s)
      raise Rejected.new(401, 'Invalid Forgejo signature')
    end
    event = headers['HTTP_X_FORGEJO_EVENT']
    raise Rejected.new(400, 'Only Forgejo push events are supported') unless event == 'push'
    json = JSON.parse(body)
    validate(json)
    unless json['repository']['full_name'] == name
      raise Rejected.new(400, 'Forgejo repository does not match webhook target')
    end
    return nil if json['deleted'] == true || /\A0+\z/.match?(json['after'])
    vcs = ForgejoRepo.new(ForgejoClient.new(host, config.fetch('token')), json)
    vcs.repo.change_in_master? ? vcs : nil
  rescue JSON::ParserError, KeyError, ArgumentError, TypeError
    raise Rejected.new(400, 'Invalid Forgejo push payload or configuration')
  end

  private

  def validate(json)
    unless json.is_a?(Hash) && json['repository'].is_a?(Hash) &&
           json['repository']['default_branch'].is_a?(String) &&
           !json['repository']['default_branch'].empty? &&
           json['repository']['full_name'].is_a?(String) &&
           json['ref'].is_a?(String) && json['after'].is_a?(String) &&
           /\A(?:[0-9a-f]{40}|[0-9a-f]{64})\z/.match?(json['after'])
      raise Rejected.new(400, 'Invalid Forgejo push payload')
    end
  end
end
