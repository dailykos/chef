# TODO: add copyright stuff
# Really we're just adapting the cookbook file one, so probably just take the
# copyright info from that one

require File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "spec_helper"))

describe Chef::Resource::EncryptedCookbookFile do
  before do
    @cookbook_file = Chef::Resource::EncryptedCookbookFile.new('encrypted_tarball.tgz')
  end
  
  it "uses the name parameter for the source parameter" do
    @cookbook_file.name.should == 'encrypted_tarball.tgz'
  end
  
  it "has a source parameter" do
    @cookbook_file.name('config_file.conf')
    @cookbook_file.name.should == 'config_file.conf'
  end
  
  it "defaults to a nil cookbook parameter (current cookbook will be used)" do
    @cookbook_file.cookbook.should be_nil
  end
  
  it "has a cookbook parameter" do
    @cookbook_file.cookbook("munin")
    @cookbook_file.cookbook.should == 'munin'
  end
  
  it "sets the provider to Chef::Provider::EncryptedCookbookFile" do
    @cookbook_file.provider.should == Chef::Provider::EncryptedCookbookFile
  end

end
