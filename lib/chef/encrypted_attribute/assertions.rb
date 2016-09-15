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

require 'chef/encrypted_attribute/exceptions'

class Chef
  class EncryptedAttribute
    # Include some assertions that throw exceptions if not met.
    module Assertions
      # Checks some assertions related with OpenSSL AEAD support, required to
      # to use [GCM](http://en.wikipedia.org/wiki/Galois/Counter_Mode).
      #
      # @param algorithm [String] the name of the algorithm to use.
      # @return void
      # @raise [RequirementsFailure] if any of the requirements to use AEAD is
      #   not met.
      def assert_aead_requirements_met!(algorithm)
        unless OpenSSL::Cipher.method_defined?(:auth_data=)
          fail RequirementsFailure,
               'The used Encrypted Attributes protocol version requires Ruby '\
               '>= 1.9'
        end
        return if OpenSSL::Cipher.ciphers.include?(algorithm)
        fail RequirementsFailure,
             'The used Encrypted Attributes protocol version requires an '\
             "OpenSSL version with \"#{algorithm}\" algorithm support"
      end
    end
  end
end
