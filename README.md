# Ezid::Client

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

See the test suite for more examples.

Create (Mint)

```ruby
>> identifier = Ezid::Identifier.create(shoulder: "ark:/99999/fk4")
I, [2014-12-04T15:06:02.428445 #86655]  INFO -- : EZID MINT ark:/99999/fk4 -- success: ark:/99999/fk4rx9d523
I, [2014-12-04T15:06:03.249793 #86655]  INFO -- : EZID GET ark:/99999/fk4rx9d523 -- success: ark:/99999/fk4rx9d523
=> #<Ezid::Identifier id="ark:/99999/fk4rx9d523" status="public" target="http://ezid.cdlib.org/id/ark:/99999/fk4rx9d523" created="2014-12-04 20:06:02 UTC">
>> identifier.id
=> "ark:/99999/fk4rx9d523"
>> identifier.status
=> "public"
>> identifier.target
=> "http://ezid.cdlib.org/id/ark:/99999/fk4rx9d523"
```

Retrieve (Get)

```ruby
>> identifier = Ezid::Identifier.find("ark:/99999/fk4rx9d523")
I, [2014-12-04T15:07:00.648676 #86655]  INFO -- : EZID GET ark:/99999/fk4rx9d523 -- success: ark:/99999/fk4rx9d523
=> #<Ezid::Identifier id="ark:/99999/fk4rx9d523" status="public" target="http://ezid.cdlib.org/id/ark:/99999/fk4rx9d523" created="2014-12-04 20:06:02 UTC">
```

Update (Modify)

```ruby
>> identifier.target = "http://example.com"
=> "http://example.com"
>> identifier.save
I, [2014-12-04T15:11:57.263906 #86734]  INFO -- : EZID MODIFY ark:/99999/fk4rx9d523 -- success: ark:/99999/fk4rx9d523
I, [2014-12-04T15:11:58.099128 #86734]  INFO -- : EZID GET ark:/99999/fk4rx9d523 -- success: ark:/99999/fk4rx9d523
=> #<Ezid::Identifier id="ark:/99999/fk4rx9d523" status="public" target="http://example.com" created="2014-12-04 20:06:02 UTC">
```

Delete

```ruby
>> identifier = Ezid::Identifier.create(shoulder: "ark:/99999/fk4", status: "reserved")
I, [2014-12-04T15:12:39.976930 #86734]  INFO -- : EZID MINT ark:/99999/fk4 -- success: ark:/99999/fk4n58pc0r
I, [2014-12-04T15:12:40.693256 #86734]  INFO -- : EZID GET ark:/99999/fk4n58pc0r -- success: ark:/99999/fk4n58pc0r
=> #<Ezid::Identifier id="ark:/99999/fk4n58pc0r" status="reserved" target="http://ezid.cdlib.org/id/ark:/99999/fk4n58pc0r" created="2014-12-04 20:12:39 UTC">
>> identifier.delete
I, [2014-12-04T15:12:48.853964 #86734]  INFO -- : EZID DELETE ark:/99999/fk4n58pc0r -- success: ark:/99999/fk4n58pc0r
=> #<Ezid::Identifier id="ark:/99999/fk4n58pc0r" DELETED>
```

## Metadata handling

See `Ezid::Metadata`.

## Authentication

Credentials can be provided in any -- or a combination -- of these ways:

- Environment variables `EZID_USER` and/or `EZID_PASSWORD`;

- Client configuration:

```ruby
Ezid::Client.configure do |config|
  config.user = "eziduser"
  config.password = "ezidpass"
end
```

- At client initialization (only if using Ezid::Client explicity):

```ruby
client = Ezid::Client.new(user: "eziduser", password: "ezidpass")
```

## Running the tests

See http://ezid.cdlib.org/doc/apidoc.html#testing-the-api.

Integration tests have been tagged `type: :feature`.  In order to run those tests successfully, you must supply the password for the test account "apitest" (contact EZID).  You can exclude the integration tests with the RSpec option `--tag ~type:feature`.

## Contributing

1. Fork it ( https://github.com/[my-github-username]/ezid-client/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
