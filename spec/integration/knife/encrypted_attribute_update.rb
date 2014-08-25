#
# Author:: Xabier de Zuazo (<xabier@onddo.com>)
# Copyright:: Copyright (c) 2014 Onddo Labs, SL. (www.onddo.com)
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
require 'chef/knife/encrypted_attribute_update'

describe Chef::Knife::EncryptedAttributeUpdate do
  extend ChefZero::RSpec

  when_the_chef_server 'is ready to rock!' do
    before do
      Chef::Config[:knife][:encrypted_attributes] = Mash.new
      Chef::EncryptedAttribute::RemoteClients.cache.clear
      Chef::EncryptedAttribute::RemoteNodes.cache.clear
      Chef::EncryptedAttribute::RemoteUsers.cache.clear
      Chef::EncryptedAttribute::RemoteNode.cache.max_size(0)

      Chef::Knife::EncryptedAttributeUpdate.load_deps

      @admin = Chef::ApiClient.new
      @admin.name(Chef::Config[:node_name])
      @admin.admin(true)
      admin_hs = @admin.save
      @admin.public_key(admin_hs['public_key'])
      @admin.private_key(admin_hs['private_key'])
      private_key = OpenSSL::PKey::RSA.new(@admin.private_key)
      allow_any_instance_of(Chef::EncryptedAttribute::LocalNode).to receive(:key).and_return(private_key)

      @node1 = Chef::Node.new
      @node1.name('node1')
      @node1.save
      @node1_client = Chef::ApiClient.new
      @node1_client.name('node1')
      @node1_client.admin(false)
      node_hs = @node1_client.save
      @node1_client.public_key(node_hs['public_key'])
      @node1_client.private_key(node_hs['private_key'])

      @node2 = Chef::Node.new
      @node2.name('node2')
      @node2.save
      @node2_client = Chef::ApiClient.new
      @node2_client.name('node2')
      @node2_client.admin(false)
      @node2_client.save

      Chef::EncryptedAttribute.create_on_node(
        'node1',
        %w(encrypted attribute),
        'random-data',
        { :client_search => 'admin:true', :node_search => 'role:webapp' }
      )

      @stdout = StringIO.new
      allow_any_instance_of(Chef::Knife::UI).to receive(:stdout).and_return(@stdout)
    end
    after do
      @admin.destroy
      @node1.destroy
      @node1_client.destroy
    end

    it 'the written node should be able to read the encrypted key after update' do
      knife = Chef::Knife::EncryptedAttributeUpdate.new(%w(
        node1 encrypted.attribute
      ))
      knife.run

      node_private_key = OpenSSL::PKey::RSA.new(@node1_client.private_key)
      allow_any_instance_of(Chef::EncryptedAttribute::LocalNode).to receive(:key).and_return(node_private_key)
      expect(Chef::EncryptedAttribute.load_from_node('node1', %w(
        encrypted attribute
      ))).to eql('random-data')
    end

    it 'the client should not be able to update the encrypted attribute by default' do
      enc_attr = Chef::EncryptedAttribute.new
      enc_attr.create_on_node('node1', %w(encrypted attribute), 'random-data')
      knife = Chef::Knife::EncryptedAttributeUpdate.new(%w(
        node1 encrypted.attribute
        --client-search *:*
      ))
      expect { knife.run }.to raise_error(Chef::EncryptedAttribute::DecryptionFailure, /Attribute data cannot be decrypted by the provided key/)
    end

    it 'should not update the encrypted attribute if the privileges are the same' do
      knife = Chef::Knife::EncryptedAttributeUpdate.new(%w(
        node1 encrypted.attribute
        --client-search admin:true
        --node-search role:webapp
      ))
      knife.run
      @stdout.rewind
      knife = Chef::Knife::EncryptedAttributeUpdate.new(%w(
        node1 encrypted.attribute
        --client-search admin:true
        --node-search role:webapp
      ))
      knife.run
      expect(@stdout.string).to match(/Encrypted attribute does not need updating\./)
    end

    it 'should update the encrypted attribute if the privileges has changed' do
      knife = Chef::Knife::EncryptedAttributeUpdate.new(%w(
        node1 encrypted.attribute
        --client-search admin:true
        --node-search role:webapp
      ))
      knife.run
      @stdout.rewind
      knife = Chef::Knife::EncryptedAttributeUpdate.new(%w(
        node1 encrypted.attribute
        --client-search admin:false
        --node-search role:webapp
      ))
      knife.run
      expect(@stdout.string).to match(/Encrypted attribute updated\./)
    end

    it 'should print error message when the attribute does not exists' do
      knife = Chef::Knife::EncryptedAttributeUpdate.new(%w(node1 non.existent))
      expect(knife.ui).to receive(:fatal).with('Encrypted attribute not found')
      expect { knife.run }.to raise_error(SystemExit)
    end

    it 'should print usage and exit when a node name is not provided' do
      knife = Chef::Knife::EncryptedAttributeUpdate.new([])
      expect(knife).to receive(:show_usage)
      expect(knife.ui).to receive(:fatal)
      expect { knife.run }.to raise_error(SystemExit)
    end

    it 'should print usage and exit when an attribute is not provided' do
      knife = Chef::Knife::EncryptedAttributeUpdate.new(%w(node1))
      expect(knife).to receive(:show_usage)
      expect(knife.ui).to receive(:fatal)
      expect { knife.run }.to raise_error(SystemExit)
    end

  end
end