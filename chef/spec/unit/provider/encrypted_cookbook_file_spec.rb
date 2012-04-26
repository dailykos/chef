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

    # stub out load_secret stuff here?
    # make sure to test all the methods of loading the secret explicitly
    default_path = "/etc/chef/encrypted_file_secret"
    ::File.stub(:exists?).with(default_path).and_return(true)
    IO.stub(:read).with(default_path).and_return(@secret)
  end

  # We want this provider to still be able to do the same general tasks as the
  # vanilla CookbookFile provider, so bring those tests over as necessary.

  it "prefers the explicit cookbook name on the resource to the implicit one" do
    @new_resource.cookbook('nginx')
    @provider.resource_cookbook.should == 'nginx'
  end

  it "falls back to the implicit cookbook name on the resource" do
    @provider.resource_cookbook.should == 'apache2'
  end

  describe "when loading the current file state" do

    it "converts windows-y filenames to unix-y ones" do
      @new_resource.path('windows\stuff')
      @provider.load_current_resource
      @new_resource.path.should == 'windows/stuff'
    end

    it "sets the current resources path to the same as the new resource" do
      @new_resource.path('/tmp/file')
      @provider.load_current_resource
      @provider.current_resource.path.should == '/tmp/file'
    end
  end

  describe "when the enclosing directory of the target file location doesn't exist" do
    before do
      @new_resource.path("/tmp/no/such/intermediate/path/file.txt")
    end

    it "raises a specific error alerting the user to the problem" do
      lambda {@provider.action_create}.should raise_error(Chef::Exceptions::EnclosingDirectoryDoesNotExist)
    end
  end

  describe "when the file doesn't yet exist" do
    before do
      @install_to = Dir.tmpdir + '/apache2_modconf.pl'

      @current_resource = @new_resource.dup
      @provider.current_resource = @current_resource
    end

    after { ::File.exist?(@install_to) && FileUtils.rm(@install_to) }

    it "loads the current file state" do
      @provider.load_current_resource
      @provider.current_resource.checksum.should be_nil
    end

    it "looks up a file from the cookbook cache" do
      expected = CHEF_SPEC_DATA + "/cookbooks/apache2/files/default/apache2_module_conf_generate.pl"
      @provider.file_cache_location.should == expected
    end

    it "sets access controls on a file" do
      @new_resource.owner(0)
      @new_resource.group(0)
      @new_resource.mode(0400)
      Chef::FileAccessControl.any_instance.should_receive(:set_all)
      @provider.set_all_access_controls('/tmp/foo')
      @provider.new_resource.should be_updated
    end

    it "stages the cookbook to a temporary file" do
      cache_file_location = CHEF_SPEC_DATA + "/cookbooks/apache2/files/default/apache2_module_conf_generate.pl"
      actual = nil
      Tempfile.open('rspec-staging-test') do |staging|
        staging.close
        @provider.should_receive(:set_all_access_controls).with(staging.path)
        @provider.stage_file_to_tmpdir(staging.path)
        actual = IO.read(staging.path)
      end
      actual.should == @file_content
    end

    it "installs the file from the cookbook cache" do
      @new_resource.path(@install_to)
      @provider.should_receive(:backup_new_resource)
      @provider.should_receive(:set_all_access_controls)
      @provider.action_create
      actual = IO.read(@install_to)
      actual.should == @file_content
    end

    it "installs the file for create_if_missing" do
      @new_resource.path(@install_to)
      @provider.should_receive(:set_all_access_controls)
      @provider.should_receive(:backup_new_resource)
      @provider.action_create_if_missing
      actual = IO.read(@install_to)
      actual.should == @file_content
    end

    it "marks the resource as updated by the last action" do
      @new_resource.path(@install_to)
      @provider.stub!(:backup_new_resource)
      @provider.stub!(:set_all_access_controls)
      @provider.action_create
      @new_resource.should be_updated
      @new_resource.should be_updated_by_last_action
    end

  end






end
