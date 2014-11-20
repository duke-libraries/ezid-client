# Ezid::Client

EZID API Version 2 bindings. See http://ezid.cdlib.org/doc/apidoc.html.

## Installation

Add this line to your application's Gemfile:

    gem 'ezid-client'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install ezid-client

## Usage

Create a client

```ruby
>> client = Ezid::Client.new(user: "apitest", password: "********")
=> #<Ezid::Client:0x007f857c23ca40 @user="apitest", @password="********", @session=#<Ezid::Session:0x007f857c2515a8 @cookie="sessionid=quyclw5bbnwsay0qh05isalt86xj5o1l">>
```

Mint an identifier

```ruby
>> response = client.mint_identifier("ark:/99999/fk4")
=> #<Ezid::Response:0x007f857c488010 @http_response=#<Net::HTTPCreated 201 CREATED readbody=true>, @metadata=#<Ezid::Metadata:0x007f857c488448 @elements={}>, @result="success", @message="ark:/99999/fk4988cc8j">
>> response.identifier
=> "ark:/99999/fk4988cc8j"
```

Modify identifier metadata

```ruby
>> metadata = Ezid::Metadata.new("dc.type" => "Image")
=> #<Ezid::Metadata:0x007f857c251c88 @elements={"dc.type"=>"Image"}>
>> response = client.modify_identifier("ark:/99999/fk4988cc8j", metadata)
=> #<Ezid::Response:0x007f857c53ab20 @http_response=#<Net::HTTPOK 200 OK readbody=true>, @metadata=#<Ezid::Metadata:0x007f857c53aa30 @elements={}>, @result="success", @message="ark:/99999/fk4988cc8j">
```

Get identifier metadata

```
>> response = client.get_identifier_metadata("ark:/99999/fk4988cc8j")
=> #<Ezid::Response:0x007f857c50a060 @http_response=#<Net::HTTPOK 200 OK readbody=true>, @metadata=#<Ezid::Metadata:0x007f857c509f48 @elements={"_updated"=>"1416436386", "_target"=>"http://ezid.cdlib.org/id/ark:/99999/fk4988cc8j", "_profile"=>"erc", "dc.type"=>"Image", "_ownergroup"=>"apitest", "_owner"=>"apitest", "_export"=>"yes", "_created"=>"1416436287", "_status"=>"public"}>, @result="success", @message="ark:/99999/fk4988cc8j">
>> response.metadata["dc.type"]
=> "Image"
>> puts response.metadata
_updated: 1416436386
_target: http://ezid.cdlib.org/id/ark:/99999/fk4988cc8j
_profile: erc
dc.type: Image
_ownergroup: apitest
_owner: apitest
_export: yes
_created: 1416436287
_status: public
```

## Contributing

1. Fork it ( https://github.com/[my-github-username]/ezid-client/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
