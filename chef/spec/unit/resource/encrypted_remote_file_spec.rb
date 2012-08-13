# TODO: update copyright stuff

#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2008 Opscode, Inc.
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

require File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "spec_helper"))

describe Chef::Resource::EncryptedRemoteFile do

  before(:each) do
    @resource = Chef::Resource::EncryptedRemoteFile.new("fakey_fakerton")
  end

  describe "initialize" do
    it "should create a new Chef::Resource::EncryptedRemoteFile" do
      @resource.should be_a_kind_of(Chef::Resource)
      @resource.should be_a_kind_of(Chef::Resource::File)
      @resource.should be_a_kind_of(Chef::Resource::RemoteFile)
      @resource.should be_a_kind_of(Chef::Resource::EncryptedRemoteFile)
    end
  end

  it "says its provider is EncryptedRemoteFile when the source is an absolute URI" do
    @resource.source("http://www.google.com/robots.txt")
    @resource.provider.should == Chef::Provider::EncryptedRemoteFile
    Chef::Platform.find_provider(:noplatform, 'noversion', @resource).should == Chef::Provider::EncryptedRemoteFile
  end

  it "says its provider is EncryptedCookbookFile when the source is a relative URI" do
    @resource.source('seattle.txt')
    @resource.provider.should == Chef::Provider::EncryptedCookbookFile
    Chef::Platform.find_provider(:noplatform, 'noversion', @resource).should == Chef::Provider::EncryptedCookbookFile
  end
  
  describe "source" do
    it "should accept a string for the remote file source" do
      @resource.source "something"
      @resource.source.should eql("something")
    end

    it "should have a default based on the param name" do
      @resource.source.should eql("fakey_fakerton")
    end

    it "should use only the basename of the file as the default" do
      r = Chef::Resource::EncryptedRemoteFile.new("/tmp/obit/fakey_fakerton")
      r.source.should eql("fakey_fakerton")
    end
  end
  
  describe "cookbook" do
    it "should accept a string for the cookbook name" do
      @resource.cookbook "something"
      @resource.cookbook.should eql("something")
    end
    
    it "should default to nil" do
      @resource.cookbook.should == nil
    end
  end

  describe "checksum" do
    it "should accept a string for the checksum object" do
      @resource.checksum "asdf"
      @resource.checksum.should eql("asdf")
    end

    it "should default to nil" do
      @resource.checksum.should == nil
    end
  end
  
end
