# Ezid::Client

EZID API Version 2 bindings. See http://ezid.cdlib.org/doc/apidoc.html.

## Installation

Add this line to your application's Gemfile:

    gem 'ezid-client'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install ezid-client

## Basic Usage

See `Ezid::Client` class for details.

**Create a client**

```
>> client = Ezid::Client.new(user: "apitest")
=> #<Ezid::Client:0x007f8ce651a890 , @user="apitest", @password="********">
```

Initialize with a block (wraps in a session)

```
>> Ezid::Client.new(user: "apitest") do |client|
?>   client.server_status("*")
>> end
I, [2014-11-20T13:23:23.120797 #86059]  INFO -- : success: session cookie returned
I, [2014-11-20T13:23:25.336596 #86059]  INFO -- : success: EZID is up
I, [2014-11-20T13:23:25.804790 #86059]  INFO -- : success: authentication credentials flushed
=> #<Ezid::Client:0x007faa5a6a9ee0 , @user="apitest", @password="********">
```

**Login**

Note that login is not required to send authenticated requests; it merely establishes a session.  See http://ezid.cdlib.org/doc/apidoc.html#authentication.

```
>> client.login
I, [2014-11-20T13:10:50.958378 #85954]  INFO -- : success: session cookie returned
=> #<Ezid::Client:0x007f8ce651a890 LOGGED_IN, @user="apitest", @password="********">
```

**Mint an identifier**

```
>> response = client.mint_identifier("ark:/99999/fk4")
I, [2014-11-20T13:11:25.894128 #85954]  INFO -- : success: ark:/99999/fk4fn19h87
=> #<Net::HTTPCreated 201 CREATED readbody=true>
>> response.identifier
=> "ark:/99999/fk4fn19h87"
```

**Get identifier metadata**

```
>> response = client.get_identifier_metadata(response.identifier)
I, [2014-11-20T13:12:08.700287 #85954]  INFO -- : success: ark:/99999/fk4fn19h87
=> #<Net::HTTPOK 200 OK readbody=true>
>> puts response.metadata
_updated: 1416507086
_target: http://ezid.cdlib.org/id/ark:/99999/fk4fn19h87
_profile: erc
_ownergroup: apitest
_owner: apitest
_export: yes
_created: 1416507086
_status: public
=> nil
```

**Logout**

```
>> client.logout
I, [2014-11-20T13:18:47.213566 #86059]  INFO -- : success: authentication credentials flushed
=> #<Ezid::Client:0x007faa5a712350 , @user="apitest", @password="********">
```

## Resource-oriented Usage

Experimental -- see `Ezid::Identifier`.

## Metadata handling

See `Ezid::Metadata`.

## Contributing

1. Fork it ( https://github.com/[my-github-username]/ezid-client/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
