# SPDX-FileCopyrightText: Copyright (c) 2016-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'faraday'
require 'json'

# JSON transport for one explicitly configured HTTPS Forgejo host.
# Redirects are not followed: credentials must stay on this host.
class ForgejoClient
  attr_reader :host

  # HTTP failure without response bodies that may contain credentials.
  class Error < StandardError
    attr_reader :status

    def initialize(status)
      @status = status
      super("Forgejo API returned HTTP #{status}")
    end
  end

  def initialize(host, token, connection = nil)
    raise ArgumentError, 'Invalid Forgejo hostname' unless /\A[a-z0-9]+(?:[.-][a-z0-9]+)*\z/.match?(host)
    raise ArgumentError, 'Missing Forgejo token' if token.to_s.empty?
    @host = host
    @connection = connection || Faraday.new(url: "https://#{host}/api/v1/")
    @connection.options.timeout = 20
    @connection.options.open_timeout = 20
    @token = token
  end

  def request(method, path, data = nil)
    headers = {
      'Authorization' => "token #{@token}",
      'Accept' => 'application/json',
      'Content-Type' => 'application/json'
    }
    response = @connection.run_request(method, path, data && JSON.generate(data), headers)
    raise Error, response.status unless (200..299).cover?(response.status)
    response.body.to_s.empty? ? nil : JSON.parse(response.body, symbolize_names: true)
  end

  # Continue until an empty page, even when the server caps the page size.
  def pages(path)
    result = []
    page = 1
    loop do
      batch = request(:get, "#{path}?limit=50&page=#{page}")
      break if batch.empty?
      result.concat(batch)
      page += 1
    end
    result
  end
end
