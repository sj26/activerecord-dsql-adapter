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

```
rails dbconsole -p
psql (14.13 (Homebrew), server 16.5)
SSL connection (protocol: TLSv1.3, cipher: TLS_AES_128_GCM_SHA256, bits: 128, compression: off)
Type "help" for help.

[postgres] >
```

```
$ rails generate migration create_posts title:string body:text
      invoke  active_record
      create    db/migrate/20241204112954_create_posts.rb

$ rails db:migrate
== 20241204112954 CreatePosts: migrating ======================================
-- create_table(:posts)
   -> 0.3887s
== 20241204112954 CreatePosts: migrated (0.3889s) =============================
```

```ruby
# db/schema.rb

ActiveRecord::Schema[7.2].define(version: 2024_12_04_112954) do
  create_table "posts", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "title"
    t.text "body"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false

    t.unique_constraint ["id"], name: "posts_id_key"
  end
end
```

DSQL does not support `CREATE DATABASE` so `db:create` and `db:drop` do not work. But `db:prepare` can load the schema for you.

## Development

After checking out the repo, run `script/setup` to install dependencies. You can also run `script/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/sj26/activerecord-dsql-adapter.
