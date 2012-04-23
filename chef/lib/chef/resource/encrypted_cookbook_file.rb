#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Seth Chisamore (<schisamo@opscode.com>)
# Copyright:: Copyright (c) 2008, 2011 Opscode, Inc.
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

require 'chef/resource/cookbook_file'
require 'chef/provider/encrypted_cookbook_file'
require 'chef/mixin/securable'

class Chef
  class Resource
    class EncryptedCookbookFile < Chef::Resource::CookbookFile
      include Chef::Mixin::Securable

      provides :encrypted_cookbook_file, :on_platforms => :all

      def initialize(name, run_context=nil)
        super
        @provider = Chef::Provider::EncryptedCookbookFile
        @resource_name = :encrypted_cookbook_file
        @action = "create"
        @source = ::File.basename(name)
        @cookbook = nil
        @provider = Chef::Provider::EncryptedCookbookFile
      end

      def source(source_filename=nil)
        set_or_return(:source, source_filename, :kind_of => String)
      end

      def cookbook(cookbook_name=nil)
        set_or_return(:cookbook, cookbook_name, :kind_of => String)
      end

    end
  end
end
