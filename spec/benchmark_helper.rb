# encoding: UTF-8
#
# Author:: Xabier de Zuazo (<xabier@zuazo.org>)
# Copyright:: Copyright (c) 2014 Onddo Labs, SL.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'rspec/autorun'
require 'chef_zero/rspec'
require 'chef/encrypted_attributes'

require 'support/silent_formatter'
RSpec.configure do |config|
  config.reset
  config.formatter = 'SilentFormatter'
end

require 'support/benchmark_helpers'
include BenchmarkHelpers
require 'support/benchmark_helpers/encrypted_attribute'
include BenchmarkHelpers::EncryptedAttribute
