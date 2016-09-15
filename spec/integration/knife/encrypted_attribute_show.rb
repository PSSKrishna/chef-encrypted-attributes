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

require 'integration_helper'
require 'chef/knife/encrypted_attribute_show'

describe Chef::Knife::EncryptedAttributeShow do
  extend ChefZero::RSpec

  when_the_chef_server 'is ready to rock!' do
    let(:node) do
      node = Chef::Node.new
      node.name('node1')
      node
    end
    before do
      clear_all_caches
      cache_size(:node, 0)

      Chef::Knife::EncryptedAttributeShow.load_deps
      @knife = Chef::Knife::EncryptedAttributeShow.new

      node.set['encrypted']['attribute'] =
        Chef::EncryptedAttribute.create('unicorns drill accurately')
      node.set['encrypted']['attri.bu\\te'] =
        Chef::EncryptedAttribute.create('escaped unicorns')
      node.save

      @stdout = StringIO.new
      allow(@knife.ui).to receive(:stdout).and_return(@stdout)
    end
    after { node.destroy }

    it 'shows the encrypted attribute' do
      @knife.name_args = %w(node1 encrypted.attribute)
      @knife.run
      expect(@stdout.string).to match(/unicorns drill accurately/)
    end

    it 'shows the encrypted attribute if needs to be escaped' do
      @knife.name_args = %w(node1 encrypted.attri\.bu\te)
      @knife.run
      expect(@stdout.string).to match(/escaped unicorns/)
    end

    it 'prints error message when the attribute does not exists' do
      @knife.name_args = %w(node1 non.existent)
      expect(@knife.ui).to receive(:fatal).with('Encrypted attribute not found')
      expect { @knife.run }.to raise_error(SystemExit)
    end

    it 'prints usage and exit when a node name is not provided' do
      @knife.name_args = []
      expect(@knife).to receive(:show_usage)
      expect(@knife.ui).to receive(:fatal)
      expect { @knife.run }.to raise_error(SystemExit)
    end

    it 'prints usage and exit when an attribute is not provided' do
      @knife.name_args = %w(node1)
      expect(@knife).to receive(:show_usage)
      expect(@knife.ui).to receive(:fatal)
      expect { @knife.run }.to raise_error(SystemExit)
    end
  end
end
