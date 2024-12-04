# Active Record Adapter for AWS Aurora DSQL

The very beginnings of an Active Record connection adapter for Amazon's AWS Aurora DSQL database.

https://docs.aws.amazon.com/aurora-dsql/latest/userguide/

## Installation

```
bundle add activerecord-dsql-adapter
```

## Usage

```
# config/database.yml
development:
  adapter: dsql
  host: abc123.dsql.us-east-1.on.aws
```

Credentials available in ENV or inside your `~/.aws/config` file will be used to generate an appropriate AWS signature as a password:

https://docs.aws.amazon.com/aurora-dsql/latest/userguide/authentication-token-ruby.html

```
$ rails console
Loading development environment (Rails 7.2.2)

dsql-example(dev)> ActiveRecord::Base.connection.raw_connection
#<PG::Connection:0x000000011dab5860 host=abc123.dsql.us-east-1.on.aws port=5432 user=admin>

dsql-example(dev)> ActiveRecord::Base.connection.execute("SELECT 1")
   (1844.8ms)  SELECT 1
=> #<PG::Result:0x00000001238b39a8 status=PGRES_TUPLES_OK ntuples=1 nfields=1 cmd_tuples=1>
```

## Development

After checking out the repo, run `script/setup` to install dependencies. You can also run `script/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/sj26/activerecord-dsql-adapter.
