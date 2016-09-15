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

describe Chef::EncryptedAttribute::RemoteUsers do
  extend ChefZero::RSpec
  let(:node_name) { Chef::Config[:node_name] }
  let(:remote_node) { Chef::EncryptedAttribute::RemoteNode.new(node_name) }
  let(:attr1) { ['any-attribute-value', 0, {}] }
  let(:attr2) { 'value2' }
  before(:all) { clear_cache(:users) }

  when_the_chef_server 'is ready to rock!' do
    before do
      @node, @client = chef_create_node(node_name) do |node|
        node.set['attr1'] = attr1
        node.set['sub-attr']['attr2'] = attr2
      end
    end
    after do
      @client.destroy
      @node.destroy
    end

    context '#name' do
      it 'returns the node name' do
        expect(remote_node.name).to eql(node_name)
      end

      it 'is able to set the node name' do
        new_name = 'alice'
        remote_node.name(new_name)
        expect(remote_node.name).to eql(new_name)
      end
    end # context #name

    context '#load_attribute' do
      it 'reads an existing node attribute' do
        expect(remote_node.load_attribute(%w(attr1))).to eql(attr1)
        expect(remote_node.load_attribute(%w(sub-attr attr2)))
          .to eql(attr2)
      end

      it 'returns nil if the attribute is not found' do
        expect(remote_node.load_attribute(%w(non-existing attr))).to eql(nil)
      end

      it 'raises an error if the attribute list is incorrect' do
        expect { remote_node.load_attribute('incorrect-attr-ary') }
          .to raise_error(ArgumentError)
      end
    end # context #load_attribute

    context '#save_attribute' do
      it 'saves the attribute' do
        remote_node.save_attribute(%w(saved-attr subattr2), 'A precious value')
        Chef::EncryptedAttribute::RemoteUsers.cache.clear
        clear_cache(:users)
        expect(remote_node.load_attribute(%w(saved-attr subattr2)))
          .to eql('A precious value')
      end

      it 'saves attributes in the cache' do
        Chef::EncryptedAttribute::RemoteUsers.cache.max_size(20)
        Chef::EncryptedAttribute::RemoteUsers.cache.clear
        remote_node.save_attribute(%w(saved-attr subattr2), 'A precious value')
        expect(remote_node.load_attribute(%w(saved-attr subattr2)))
          .to eql('A precious value') # cached
      end

      it 'throws an error if the attribute list is incorrect' do
        expect do
          remote_node.save_attribute('incorrect-attr-ary', 'some value')
        end.to raise_error(ArgumentError)
      end
    end # context #save_attribute

    context '#delete_attribute' do
      it 'deletes a node attribute' do
        node = Chef::Node.load(node_name)
        expect(node['sub-attr']['attr2']).not_to eql(nil)

        expect(remote_node.delete_attribute(%w(sub-attr attr2))).to eql(true)

        node = Chef::Node.load(node_name)
        expect(node['sub-attr']['attr2']).to eql(nil)
      end

      it 'ignores if the attribute does not exist' do
        expect(@node['non-existent-attr']).to eql(nil)
        expect(remote_node.delete_attribute(%w(non-existent-attr)))
          .to eql(false)
      end

      it 'raises an error if the attribute list is incorrect' do
        expect { remote_node.delete_attribute('incorrect-attr-ary') }
          .to raise_error(ArgumentError)
      end
    end # context #delete_attribute
  end # when_the_chef_server is ready to rock!
end
