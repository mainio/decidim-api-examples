# frozen_string_literal: true

require "net/http"
require "json"

class ApiClient
  def initialize(url:, key:, secret:)
    @url = url
    @key = key
    @secret = secret
  end

  def sign_in
    uri = URI.parse("#{url}/sign_in")

    request = Net::HTTP::Post.new(uri)
    request.body = {api_user: {key:, secret:}}.to_json
    request.content_type = "application/json"

    response = send_request(request)

    raise "Invalid response code: #{response.code}" if response.code != "200"

    @authorization = response["Authorization"]
    raise "No authorization header was returned." if authorization.nil?
  end

  def sign_out
    raise "The client is not authenticated." if authorization.nil?

    uri = URI.parse("#{url}/sign_out")

    request = Net::HTTP::Delete.new(uri)
    request["Authorization"] = authorization

    response = send_request(request)
    raise "Invalid response code: #{response.code}" if response.code != "200"
  end

  def user_details
    data = graphql_request("{ session { user { id name nickname } } }")

    data.fetch("session")&.fetch("user")&.transform_keys(&:to_sym)
  end

  private

  attr_reader :url, :key, :secret, :authorization

  def send_request(request)
    uri = request.uri
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true if uri.scheme == "https"
    http.request(request)
  end

  def graphql_request(query)
    uri = URI.parse(url)
    request = Net::HTTP::Post.new(uri)
    request["Authorization"] = authorization
    request.body = {query:}.to_json
    request.content_type = "application/json"

    response = send_request(request)
    raise "Invalid response code from the API: #{response.code}" if response.code != "200"

    body = JSON.parse(response.body)
    body["data"]
  end
end
