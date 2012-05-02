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

# Borrowing quite a bit indeed from encrypted_data_bag_item here.

require 'chef/file_access_control'
require 'chef/provider/encrypted_cookbook_file'
require 'tempfile'
require 'openssl'

class Chef
  class Provider
    class EncryptedCookbookFile < Chef::Provider::CookbookFile
      DEFAULT_SECRET_FILE = "/etc/chef/encrypted_file_secret"
      ALGORITHM = 'aes-256-cbc'

      def load_current_resource
        @current_resource = Chef::Resource::EncryptedCookbookFile.new(@new_resource.name)
        @new_resource.path.gsub!(/\\/, "/") # for Windows
        @current_resource.path(@new_resource.path)
        @current_resource
      end

      def action_create
	assert_enclosing_directory_exists!
	if file_cache_location && content_stale?
	  Chef::Log.debug("#{@new_resource} has new encrypted contents")
	  backup_new_resource
	  Tempfile.open(::File.basename(@new_resource.name)) do |staging_file|
	    secret ||= self.load_secret
	    staging_file.close
	    stage_file_to_tmpdir(staging_file.path)
	    # decrypt here?
	    ::File.open(staging_file.path, "r+") do |f|
	      enc_data = f.read
	      f.rewind
	      f.truncate(f.pos)
	      plain_data = Chef::Encryption.cipher(:decrypt, enc_data, secret)
	      f.write(plain_data)
	    end
	    FileUtils.mv(staging_file.path, @new_resource.path)
	  end
	  Chef::Log.info("#{@new_resource} created file #{@new_resource.path}")
	  @new_resource.updated_by_last_action(true)
	else
	  set_all_access_controls(@new_resource.path)
	end
	@new_resource.updated_by_last_action?
      end

      def content_stale?
	( ! ::File.exist?(@new_resource.path)) || ( ! compare_content)
      end

      def new_resource_content_checksum
        @new_resource.content && Digest::SHA2.hexdigest(Chef::Encryption.cipher(:decrypt, @new_resource.content, secret))
      end

      def compare_content
	checksum(@current_resource.path) == new_resource_content_checksum
      end

      def load_secret(path=nil)
	path = path || Chef::Config[:encrypted_file_secret] || DEFAULT_SECRET_FILE
	@secret ||= Chef::Encryption.load_secret(path)
	@secret
      end

    end
  end
end
