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
	    #plain_data = Chef::Provider::EncryptedCookbookFile.cipher(:decrypt, @new_resource.content, secret)
	    #staging_file.write(plain_data)
	    staging_file.close
	    stage_file_to_tmpdir(staging_file.path)
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
        @new_resource.content && Digest::SHA2.hexdigest(self.cipher(:decrypt, @new_resource.content, secret))
      end

      def compare_content
	checksum(@current_resource.path) == new_resource_content_checksum
      end

      def load_secret(path=nil)
	path = path || Chef::Config[:encrypted_file_secret] || DEFAULT_SECRET_FILE
	@secret ||= case path
		 when /^\w+:\/\//
		   # We have a remote key
		   begin
		     Kernel.open(path).read.strip
		   rescue Errno::ECONNREFUSED
		     raise ArgumentError, "Remote key not available from '#{path}'"
		   rescue OpenURI::HTTPError
		     raise ArgumentError, "Remote key not found at '#{path}'"
		   end
		 else
		   if !::File.exists?(path)
		     raise Errno::ENOENT, "file not found '#{path}'"
		   end
		   IO.read(path).strip
		 end
	if @secret.size < 1
	  raise ArgumentError, "invalid zero length secret in '#{path}'"
	end
	@secret
      end

      protected

	def self.cipher(direction, data, key)
	  cipher = OpenSSL::Cipher::Cipher.new(ALGORITHM)
	  cipher.send(direction)
	  cipher.pkcs5_keyivgen(key)
	  ans = cipher.update(data)
	  ans << cipher.final
	  ans
	end

	def self.decrypt_file(enc_file, plain_file, key)
	  unless ::File.exists?(enc_file)
	    raise Errno::ENOENT, "File not found: #{enc_file}"
	  end
	  fh = ::File.open(enc_file, "r+b")
	  enc_data = fh.read
	  plain_data = self.cipher(:decrypt, enc_data, key)
	  ::File.open(plain_file, "wb"){ |f| f.write(plain_data) }
	end

	def self.encrypt_file(plain_file, enc_file, key)
	  unless ::File.exists?(plain_file)
	    raise Errno::ENOENT, "File not found: #{plain_file}"
	  end
	  fh = ::File.open(plain_file, "rb")
	  plain_data = fh.read
	  enc_data = self.cipher(:encrypt, plain_data, key)
	  ::File.open(enc_file, "wb"){ |f| f.write(enc_data) }
	end

    end
  end
end
