#!/usr/bin/env ruby
# Query Xcode Cloud build runs via App Store Connect API
#
# Usage: ruby scripts/query-builds.rb

require 'dotenv'
Dotenv.load(File.expand_path('../../.env', __FILE__))

require 'spaceship'

apple_id = ENV.fetch('APPLE_ID')
ci_product_id = ENV.fetch('CI_PRODUCT_ID')

Spaceship::ConnectAPI.login(apple_id)

client = Spaceship::ConnectAPI.client.tunes_request_client
runs = client.get("v1/ciProducts/#{ci_product_id}/buildRuns", { "limit" => 50 })

runs.each do |run|
  attrs = run["attributes"]
  commit_sha = attrs.dig("sourceCommit", "commitSha")
  number = attrs["number"]
  status = attrs["executionProgress"]
  puts "Build ##{number} — #{status} — #{commit_sha}"
end
