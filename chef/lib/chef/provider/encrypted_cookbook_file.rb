#
# Author:: Jeremy Bingham (<jeremy@dailykos.com>)
# Copyright:: Copyright (c) 2011 Kos Media, LLC
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

require 'chef/file_access_control'
require 'chef/provider/encrypted_cookbook_file'
require 'tempfile'

class Chef
  class Provider
    class EncryptedCookbookFile < Chef::Provider::CookbookFile



    end
  end
end
