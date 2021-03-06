# encoding: UTF-8
# -*- mode: ruby -*-
# vi: set ft=ruby :

# More info at http://guides.rubygems.org/specification-reference/

$LOAD_PATH.push File.expand_path('../lib', __FILE__)
require 'chef/encrypted_attribute/version'
chef_version =
  if ENV.key?('CHEF_VERSION')
    ENV['CHEF_VERSION']
  else
    RUBY_VERSION < '2.1' ? ['>= 11.8', '< 12.9'] : ['>= 11.8', '< 13']
  end

Gem::Specification.new do |s|
  s.name = 'chef-encrypted-attributes'
  s.version = ::Chef::EncryptedAttribute::VERSION
  s.date = '2016-09-15'
  s.platform = Gem::Platform::RUBY
  s.summary = 'Chef Encrypted Attributes'
  s.description =
    'Chef plugin to add Node encrypted attributes support using client keys'
  s.license = 'Apache-2.0'
  s.authors = ['Xabier de Zuazo']
  s.email = 'xabier@zuazo.org'
  s.homepage = 'http://zuazo.github.io/chef-encrypted-attributes'
  s.require_path = 'lib'
  s.files = %w(
    .yardopts Rakefile LICENSE
  ) + Dir.glob('*.md') + Dir.glob('lib/**/*')
  s.test_files = Dir.glob('{test,spec,features}/*')
  s.required_ruby_version = Gem::Requirement.new('>= 2.0.0')

  s.add_development_dependency 'chef', chef_version

  # Support old deprecated Ruby versions:
  if RUBY_VERSION < '2.1'
    s.add_development_dependency 'ffi-yajl',  '<= 2.2.3'
    s.add_development_dependency 'chef-zero', '< 4.6.0'
    s.add_development_dependency 'ohai', '< 8.18.0'
  end

  s.add_development_dependency 'rake', '~> 10.0'
  s.add_development_dependency 'rack', '~> 1.0' if RUBY_VERSION < '2.2.2'
  s.add_development_dependency 'rspec-core', '~> 3.1'
  s.add_development_dependency 'rspec-expectations', '~> 3.1'
  s.add_development_dependency 'rspec-mocks', '~> 3.1'
  s.add_development_dependency 'coveralls', '~> 0.7'
  s.add_development_dependency 'simplecov', '~> 0.9'
  s.add_development_dependency 'should_not', '~> 1.1'
  s.add_development_dependency 'rubocop', '= 0.31.0' if RUBY_VERSION >= '1.9.3'
  s.add_development_dependency 'yard', '~> 0.8'

  s.cert_chain = [::File.join('certs', 'xabier_zuazo.crt')]
end
