# TODO: add copyright stuffs
# as with the resource, this is mostly adapting the cookbook_file spec, so we
# should bring that copyright over & amend a bit

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require 'ostruct'

describe Chef::Provider::EncryptedCookbookFile do
  before do
    Chef::FileAccessControl.any_instance.stub(:set_all)
    Chef::FileAccessControl.any_instance.stub(:modified?).and_return(true)
    @cookbook_repo = File.expand_path(File.join(CHEF_SPEC_DATA, "cookbooks"))
    Chef::Cookbook::FileVendor.on_create { |manifest| Chef::Cookbook::FileSystemFileVendor.new(manifest, @cookbook_repo) }

    @node = Chef::Node.new
    @cookbook_collection = Chef::CookbookCollection.new(Chef::CookbookLoader.new(@cookbook_repo))
    @run_context = Chef::RunContext.new(@node, @cookbook_collection)

    @new_resource = Chef::Resource::EncryptedCookbookFile.new('apache2_module_conf_generate.pl')
    @new_resource.cookbook_name = 'apache2'
    @provider = Chef::Provider::EncryptedCookbookFile.new(@new_resource, @run_context)

    @plain_content=<<-EXPECTED
# apache2_module_conf_generate.pl
# this is just here for show.
EXPECTED

    @secret = "abc123SECRET"
    @file_content = Chef::Provider::EncryptedCookbookFile.cipher(:encrypt, @plain_content, @secret)
  end

  # we still want the other tests, so bring them over

  describe "when the enclosing directory of the target file location doesn't exist" do
    before do
      @new_resource.path("/tmp/no/such/intermediate/path/file.txt")
    end

    it "raises a specific error alerting the user to the problem" do
      lambda {@provider.action_create}.should raise_error(Chef::Exceptions::EnclosingDirectoryDoesNotExist)
    end
  end








end
