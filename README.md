# EZID Client

EZID API Version 2 bindings. See http://ezid.cdlib.org/doc/apidoc.html.

[![Gem Version](https://badge.fury.io/rb/ezid-client.svg)](http://badge.fury.io/rb/ezid-client)
[![Build Status](https://travis-ci.org/duke-libraries/ezid-client.svg?branch=master)](https://travis-ci.org/duke-libraries/ezid-client)

## Installation

Add this line to your application's Gemfile:

    gem 'ezid-client'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install ezid-client

## Basic Resource-oriented Usage (CRUD)

*See the test suite for more examples.*

**Create** (Mint/Create)

[Mint an identifier on a shoulder](http://ezid.cdlib.org/doc/apidoc.html#operation-mint-identifier)

*Added in v1.4.0:* `Ezid::Identifier.mint` class method.

```
>> identifier = Ezid::Identifier.mint("ark:/99999/fk4")
I, [2016-03-01T22:20:08.505323 #35148]  INFO -- : EZID MintIdentifier -- success: ark:/99999/fk4tq65d6k
=> #<Ezid::Identifier id=ark:/99999/fk4tq65d6k>

>> identifier.status
I, [2016-03-01T22:20:22.323650 #35148]  INFO -- : EZID GetIdentifierMetadata -- success: ark:/99999/fk4tq65d6k
=> "public"

>> identifier.target
=> "http://ezid.cdlib.org/id/ark:/99999/fk4tq65d6k"
```

A default shoulder can be configured:

- By environment variable (added in v0.9.1):

```sh
export EZID_DEFAULT_SHOULDER="ark:/99999/fk4"
```

- By client configuration:

```ruby
Ezid::Client.configure do |config|
  config.default_shoulder = "ark:/99999/fk4"
end
```

New identifiers will then be minted on the default shoulder when a shoulder is not specified:

```
>> identifier = Ezid::Identifier.mint
I, [2014-12-09T11:22:34.499860 #32279]  INFO -- : EZID MintIdentifier -- success: ark:/99999/fk43f4wd4v
=> #<Ezid::Identifier id="ark:/99999/fk43f4wd4v">
```

[Create a specific identifier](http://ezid.cdlib.org/doc/apidoc.html#operation-create-identifier)

*Changed in v1.4.0:* `Ezid::Identifier.create` now expects the first argument to be the identifier (String) to create; the second optional argument is a hash of metadata elements. Passing the identifier in an `:id` hash option is deprecated and will be removed in v2.0. The `:shoulder` hash option is likewise deprecated; use `Ezid::Identifier.mint(shoulder, metadata)` instead.

```
>> identifier = Ezid::Identifier.create("ark:/99999/fk4rx9d523/12345")
I, [2014-12-09T11:21:42.077297 #32279]  INFO -- : EZID CreateIdentifier -- success: ark:/99999/fk4rx9d523/12345
=> #<Ezid::Identifier id="ark:/99999/fk4rx9d523/12345">
```

**Retrieve** (Get Metadata)

```
>> identifier = Ezid::Identifier.find("ark:/99999/fk4rx9d523")
I, [2014-12-04T15:07:00.648676 #86655]  INFO -- : EZID GetIdentifierMetadata -- success: ark:/99999/fk4rx9d523
=> #<Ezid::Identifier id="ark:/99999/fk4rx9d523" status="public" target="http://ezid.cdlib.org/id/ark:/99999/fk4rx9d523" created="2014-12-04 20:06:02 UTC">
```

**Update** (Modify)

```
>> identifier.target
=> "http://ezid.cdlib.org/id/ark:/99999/fk43f4wd4v"

>> identifier.target = "http://example.com"
=> "http://example.com"

>> identifier.save
I, [2014-12-09T11:24:26.321801 #32279]  INFO -- : EZID ModifyIdentifier -- success: ark:/99999/fk43f4wd4v
=> #<Ezid::Identifier id="ark:/99999/fk43f4wd4v">

>> identifier.target
I, [2014-12-09T11:24:27.039288 #32279]  INFO -- : EZID GetIdentifierMetadata -- success: ark:/99999/fk43f4wd4v
=> "http://example.com"
```

*Added in v1.4.0:* `Ezid::Identifier.modify(id, metadata)` class method. In support of more efficient updating of known identifiers, this method skips the GetIdentifierMetadata request used by `.find`. The operation will raise the `Ezid::IdentifierNotFoundError` if the EZID identifier does not exist.

**Delete**

*Identifier status must be "reserved" to delete.* http://ezid.cdlib.org/doc/apidoc.html#operation-delete-identifier

```
>> identifier = Ezid::Identifier.mint("ark:/99999/fk4", status: "reserved")
I, [2016-03-01T22:26:08.645858 #36701]  INFO -- : EZID MintIdentifier -- success: ark:/99999/fk4pz5fm1b
=> #<Ezid::Identifier id=ark:/99999/fk4pz5fm1b>

>> identifier.delete
I, [2016-03-01T22:26:14.829731 #36701]  INFO -- : EZID GetIdentifierMetadata -- success: ark:/99999/fk4pz5fm1b
I, [2016-03-01T22:26:15.711390 #36701]  INFO -- : EZID DeleteIdentifier -- success: ark:/99999/fk4pz5fm1b
=> #<Ezid::Identifier id=ark:/99999/fk4pz5fm1b [DELETED]>
```

## Batch Download

See http://ezid.cdlib.org/doc/apidoc.html#parameters. Repeated values should be given as an array value for the parameter key.

*Added in v1.3.0:* `Ezid::BatchDownload` class.

```
>> batch = Ezid::BatchDownload.new(:csv)
 => #<Ezid::BatchDownload format=:csv>

>> batch.column = ["_id", "_target"]
 => ["_id", "_target"]

>> batch.createdAfter = Date.today.to_time
 => 2016-02-24 00:00:00 -0500

>> batch
 => #<Ezid::BatchDownload column=["_id", "_target"] createdAfter=1456290000 format=:csv>

>> batch.download_url
I, [2016-02-24T18:03:40.828005 #1084]  INFO -- : EZID BatchDownload -- success: http://ezid.cdlib.org/download/4a63401e17.csv.gz
 => "http://ezid.cdlib.org/download/4a63401e17.csv.gz"

>> batch.download_file
File successfully download to /current/working/directory/4a63401e17.csv.gz.
 => nil
 ```

## Metadata handling

Accessors are provided to ease the use of EZID [reserved metadata elements](http://ezid.cdlib.org/doc/apidoc.html#internal-metadata) and [metadata profiles](http://ezid.cdlib.org/doc/apidoc.html#metadata-profiles):

**Reserved elements** can be read and written using the name of the element without the leading underscore:

```
>> identifier.status                 # reads "_status" element
=> "public"

>> identifier.status = "unavailable" # writes "_status" element
=> "unavailable"
```

Notes:
- `_crossref` is an exception because `crossref` is also the name of a metadata profile and a special element.  Use `identifier._crossref` to read and `identifier._crossref = value` to write.
- Reserved elements which are not user-writeable do not implement writers.
- Special readers are implemented for reserved elements having date/time values (`_created` and `_updated`) which convert the string time values of EZID to Ruby `Time` instances.

**Metadata profile elements** can be read and written using the name of the element, replacing the dot (".") with an underscore:

```
>> identifier.dc_type           # reads "dc.type" element
=> "Collection"

>> identifier.dc_type = "Image" # writes "dc.type" element
=> "Image"
```

Accessors are also implemented for the `crossref`, `datacite`, and `erc` elements as described in the EZID API documentation.

## Authentication

Credentials can be provided in any -- or a combination -- of these ways:

- Environment variables:

```sh
export EZID_USER="eziduser"
export EZID_PASSWORD="ezidpass"
```

- Client configuration:

```ruby
Ezid::Client.configure do |config|
  config.user = "eziduser"
  config.password = "ezidpass"
end
```

- At client initialization (only if explicitly instantiating `Ezid::Client`):

```ruby
client = Ezid::Client.new(user: "eziduser", password: "ezidpass")
```

## Alternate Host and Port

By default `Ezid::Client` connects via SSL over port 443 to the EZID host at [ezid.cdlib.org](https://ezid.cdlib.org), but the host, port and SSL settings may be overridden:

- By environment variables:

```sh
export EZID_HOST="localhost"
export EZID_PORT=8443
export EZID_USE_SSL="true"
```

- Client configuration:

```ruby
Ezid::Client.configure do |config|
  config.host = "localhost"
  config.port = 8443
  config.use_ssl = true
end
```

- At client initialization (only if explicitly instantiating `Ezid::Client`):

```ruby
client = Ezid::Client.new(host: "localhost", port: 80)
```

## HTTP Timeout

The default HTTP timeout is set to 300 seconds (5 minutes). The setting can be customized:

- By environment variable:

```sh
export EZID_TIMEOUT=600
```

- Client configuration:

```ruby
Ezid::Client.configure do |config|
  config.timeout = 600
end
```

- At client initialization

```ruby
client = Ezid::Client.new(timeout: 600)
```

## Test Helper

If you have tests that (directly or indirectly) use `ezid-client` you may want to require the test helper module:

```ruby
require "ezid/test_helper"
```

The module provides constants:

- `TEST_ARK_SHOULDER` => "ark:/99999/fk4"
- `TEST_DOI_SHOULDER` => "doi:10.5072/FK2"
- `TEST_USER` => "apitest"
- `TEST_HOST` => "ezid.cdlib.org"
- `TEST_PORT` => 443

The test user password is not provided - contact EZID and configure as above - or use your own EZID credentials, since all accounts can mint/create on the test shoulders.

A convenience method `ezid_test_mode!` is provided to configure the client to:

- authenticate as `TEST_USER`
- use `TEST_HOST` as the host and `TEST_PORT` as the port
- use `TEST_ARK_SHOULDER` as the default shoulder
- log to the null device (instead of default STDERR)

See also https://github.com/duke-libraries/ezid-client/wiki/Mock-Identifier for an example of a mock identifier object.

## Running the ezid-client tests

See http://ezid.cdlib.org/doc/apidoc.html#testing-the-api.

In order to run the integration tests successfully, you must supply the password for the test account "apitest" (contact EZID).  To run the test suite without the integration tests, use the `rake ci` task.

## Contributing

1. Fork it ( https://github.com/[my-github-username]/ezid-client/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
