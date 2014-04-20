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

require 'chef/encrypted_attribute/attribute_body/version'
require 'chef/encrypted_attribute/exceptions'

class Chef
  class EncryptedAttribute
    class AttributeBody
      class Version0 < Chef::EncryptedAttribute::AttributeBody::Version

        def encrypt(value, public_keys)
          value_json = json_encode(value)
          public_keys = remove_dup_keys(public_keys)
          self['encrypted_rsa_data'] = Mash.new(Hash[
            public_keys.map do |public_key|
              [
                node_key(public_key),
                encrypt_value(public_key, value_json),
              ]
            end
          ])
          self
        end

        def decrypt(key)
          # TODO check input and enc_attr
          enc_value = self['encrypted_rsa_data'][node_key(key.public_key)]
          value_json = decrypt_value(key, enc_value)
          json_decode(value_json)
          # we avoid saving the decrypted value, only return it
        end

        def can_be_decrypted_by?(keys)
          remove_dup_keys(keys).reduce(true) do |r, k|
            r and self['encrypted_rsa_data'].kind_of?(Hash) and
              self['encrypted_rsa_data'].has_key?(node_key(k))
          end
        end

        def needs_update?(keys)
          keys = remove_dup_keys(keys)
          not can_be_decrypted_by?(keys) && self['encrypted_rsa_data'].keys.count == keys.count
        end

        protected

        def remove_dup_keys(keys)
          keys = [ keys ].flatten
          keys.map do |k|
            k.kind_of?(String) ? k = OpenSSL::PKey::RSA.new(k) : k
          end.uniq { |k| k.public_key.to_s.chomp }
        end

        def json_encode(o)
          # Array to avoid using quirks mode, create standard JSON
          [ o ].to_json
        end

        def json_decode(o)
          # TODO invalid JSON exception
          JSON.parse(o)[0]
        end

        def node_key(public_key)
          if public_key.kind_of?(String)
            public_key = OpenSSL::PKey::RSA.new(public_key)
          end
          Digest::SHA1.hexdigest(public_key.to_der)
        end

        def encrypt_value(public_key, value)
          if public_key.kind_of?(String)
            public_key = OpenSSL::PKey::RSA.new(public_key)
          end
          Base64.encode64(public_key.public_encrypt(value))
        end

        def decrypt_value(key, value)
          key.private_decrypt(Base64.decode64(value))
        end

      end
    end
  end
end