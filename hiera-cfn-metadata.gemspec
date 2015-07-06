require 'rubygems'
require 'rubygems/package_task'

spec = Gem::Specification.new do |gem|
    gem.name = "hiera-cfn-metadata"
    gem.version = "0.0.3"
    gem.license = "Apache-2.0"
    gem.summary = "Module for using CloudFormation resource metadata as a hiera backend"
    gem.email = "jonathan.sokolowski@gmail.com"
    gem.author = "Jonathan Sokolowski"
    gem.homepage = "http://github.com/jsok/hiera-cfn-metadata"
    gem.description = "Hiera backend for retrieving CloudFormation resource metadata and parsing it as a JSON data source"
    gem.require_path = "lib"
    gem.files = FileList["lib/**/*"].to_a
    gem.add_dependency('aws-sdk', '~> 2')
end
