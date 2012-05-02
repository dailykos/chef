# TODO: add author stuff; this file will be heavily derived from the data bag
# encrypted item stuff, of course

# Moving the encryption functions in common between encrypted data bag items,
# encrypted cookbook files, and the (coming) encrypted remote files into one
# lib for ease of reuse.

require 'openssl'
require 'open-uri'

class Chef::Encryption
  # TODO: we're going to be seeing different base files. Need to reconcile and
  # take legacy ones into account...
  
  DEFAULT_SECRET_FILE = "/etc/chef/encrypted_secret"
  ALGORITHM = 'aes-256-cbc'

  def self.load_secret(path=nil)
    path = path || Chef::Config[:encrypted_secret] || DEFAULT_SECRET_FILE
    secret = case path
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
               if !File.exists?(path)
                 raise Errno::ENOENT, "file not found '#{path}'"
               end
               IO.read(path).strip
             end
    if secret.size < 1
      raise ArgumentError, "invalid zero length secret in '#{path}'"
    end
    secret
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

end
