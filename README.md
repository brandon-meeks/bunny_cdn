[![Gem Version](https://badge.fury.io/rb/bunny_cdn.svg)](https://badge.fury.io/rb/bunny_cdn)
[![Maintainability](https://api.codeclimate.com/v1/badges/2cc8e5b9529c32d7473f/maintainability)](https://codeclimate.com/github/brandon-meeks/bunny_cdn/maintainability)

# BunnyCdn

This gem allows you to interact with the BunnyCDN API via the Pull Zones and Storage APIs.

> **⚠️ v2.0 Breaking Change:** This is a complete rewrite. The old class-based global configuration was replaced with an instance-based client. See [Migrating from v1](#migrating-from-v1) below.

You need an account with [BunnyCDN](https://bunnycdn.com/).

## Requirements

- Ruby >= 3.1.0

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'bunny_cdn'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install bunny_cdn

## Quick Start

```ruby
client = BunnyCdn::Client.new(api_key: ENV["BUNNY_API_KEY"])

# Pull Zones
client.pull_zones.list
client.pull_zones.find(123)
client.pull_zones.create(name: "my-zone", type: 0, origin_url: "https://example.com")

# Storage
client.storage(zone_name: "my-storage-zone").list
client.storage(zone_name: "my-storage-zone", region: "ny").upload("/path/to/file.txt", "Hello")
```

## Client

Create a client with your BunnyCDN API key:

```ruby
client = BunnyCdn::Client.new(api_key: "your-api-key")
```

Options:

| Option | Default | Description |
|--------|---------|-------------|
| `api_key` | (required) | Your BunnyCDN API key |
| `base_url` | `https://api.bunny.net` | API base URL |
| `adapter` | `Faraday.default_adapter` | Faraday adapter for HTTP |

The client configures Faraday with retry middleware (max 3 retries on timeouts and server errors). All requests set `AccessKey` and `Accept: application/json` headers automatically.

### Resource Accessors

```ruby
client.pull_zones   # => BunnyCdn::Resources::PullZones (memoized)
client.storage(zone_name: "my-zone")                    # => BunnyCdn::Resources::Storage
client.storage(zone_name: "my-zone", region: "ny")      # with region override
```

## Pull Zones

All Pull Zone operations use `client.pull_zones`.

### List

```ruby
# Default: page 1, 1000 per page
client.pull_zones.list

# Custom pagination
client.pull_zones.list(page: 2, per_page: 50)
```

### Find

```ruby
client.pull_zones.find(123)
```

### Create

```ruby
client.pull_zones.create(name: "my-zone", type: 0, origin_url: "https://origin.example.com")
```

### Delete

```ruby
client.pull_zones.delete(123)
```

### Purge Cache

```ruby
# Purge entire pull zone cache
client.pull_zones.purge(123)

# Purge by cache tag
client.pull_zones.purge_by_tag(123, "my-tag")
```

### Hostnames

```ruby
# Add a hostname to a pull zone
client.pull_zones.add_hostname(123, "cdn.example.com")

# If the hostname is already registered, returns { "success" => true, "skipped" => true }
```

### SSL

```ruby
client.pull_zones.load_free_ssl(hostname: "cdn.example.com")
```

### Health Check

```ruby
if client.pull_zones.health_check
  puts "API is healthy"
else
  puts "API is down"
end
```

## Storage

Storage operations target the BunnyCDN storage API. Each call specifies the storage zone name. The connection is routed to the correct regional subdomain automatically.

### Regions

Available regions:

| Key | Location |
|-----|----------|
| `de` | Frankfurt, DE |
| `uk` | London, UK |
| `ny` | New York, US |
| `la` | Los Angeles, US |
| `sg` | Singapore, SG |
| `se` | Stockholm, SE |
| `br` | São Paulo, BR |
| `jh` | Johannesburg, SA |
| `syd` | Sydney, SYD |

If no region is specified, `de` (Frankfurt) is used.

### List Files

```ruby
client.storage(zone_name: "my-zone").list                 # root
client.storage(zone_name: "my-zone").list(path: "images") # /images/
```

A trailing slash is appended automatically if missing.

### Download a File

```ruby
data = client.storage(zone_name: "my-zone").get("images/photo.jpg")
# Returns raw file body (StringIO / binary string)
```

### Upload a File

Two approaches:

```ruby
storage = client.storage(zone_name: "my-zone")

# 1. From a file path on disk
storage.upload("images/photo.jpg", "/local/path/photo.jpg")

# 2. From a Rack-style uploaded file (e.g. Rails file input)
storage.upload("images/photo.jpg", uploaded_file)
```

The uploaded file must respond to `original_filename` and `tempfile`, or be a String path.

### Delete a File

```ruby
client.storage(zone_name: "my-zone").delete("images/old-photo.jpg")
```

## Error Handling

All API errors raise `BunnyCdn::ApiError`:

```ruby
begin
  client.pull_zones.find(999)
rescue BunnyCdn::ApiError => e
  puts e.message       # "[BunnyCdn] pullzone/999 failed: 404 Not Found"
  puts e.status        # 404
  puts e.response      # parsed JSON or raw string body
end
```

## Migrating from v1

v2 replaces the global class-based API with an instance-based client.

### Before (v1)

```ruby
BunnyCdn.configure do |config|
  config.apiKey = ENV["BUNNY_API_KEY"]
  config.storageZone = "my-zone"
  config.region = "de"
end

BunnyCdn::Storage.uploadFile("path/to/file.txt", file_data)
BunnyCdn::PullZone.list
```

### After (v2)

```ruby
client = BunnyCdn::Client.new(api_key: ENV["BUNNY_API_KEY"])

# Storage — zone and region are per-call, not global
client.storage(zone_name: "my-zone").upload("path/to/file.txt", file_data)

# Pull Zones — single client covers all operations
client.pull_zones.list
```

### Method Mapping

| v1 | v2 |
|----|----|
| `BunnyCdn.configure { ... }` | `BunnyCdn::Client.new(api_key: ...)` |
| `BunnyCdn::PullZone.list` | `client.pull_zones.list` |
| `BunnyCdn::PullZone.find(id)` | `client.pull_zones.find(id)` |
| `BunnyCdn::PullZone.create(...)` | `client.pull_zones.create(...)` |
| `BunnyCdn::PullZone.delete(id)` | `client.pull_zones.delete(id)` |
| `BunnyCdn::Storage.uploadFile(...)` | `client.storage(...).upload(...)` |
| `BunnyCdn::Storage.uploadFormFile(...)` | `client.storage(...).upload(...)` |
| `BunnyCdn::Storage.list(...)` | `client.storage(...).list(...)` |
| `BunnyCdn::Storage.get(...)` | `client.storage(...).get(...)` |
| `BunnyCdn::Storage.delete(...)` | `client.storage(...).delete(...)` |

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bundle exec rspec` to run the tests. You can also run `bin/console` for an interactive prompt.

To install this gem onto your local machine, run `bundle exec rake install`. 

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/brandon-meeks/bunny_cdn.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the BunnyCdn project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/brandon-meeks/bunny_cdn/blob/master/CODE_OF_CONDUCT.md).
