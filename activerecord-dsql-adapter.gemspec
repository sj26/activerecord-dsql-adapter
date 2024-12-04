# frozen_string_literal: true

require "rubygems"

Gem::Specification.new do |spec|
  spec.name = "activerecord-dsql-adapter"
  spec.version = "0.1.1"
  spec.authors = ["Samuel Cochran"]
  spec.email = ["sj26@sj26.com"]

  spec.summary = "ActiveRecord adapter for AWS Aurora DSQL (PostgreSQL)"
  spec.required_ruby_version = ">= 3.0.0"

  spec.homepage = "https://github.com/sj26/activerecord-dsql-adapter"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = spec.homepage + "/releases"

  spec.files = Dir["README.md", "lib/**/*"]

  spec.add_dependency "activerecord", "~> 7.2.0"
  spec.add_dependency "pg", "~> 1.1"
  spec.add_dependency "aws-sdk-dsql"
end
