require 'spec_helper'
require 'knife-boxer/hashified_cookbook'

describe KnifeBoxer::HashifiedCookbook do

  let(:config) do
    { node_name: "kallistec" }
  end

  let(:expected_fingerprint) { "45ddfdeaf0811714b0b81b574d19d7a456624a3a" }

  let(:fingerprint_chunks) do
    [ expected_fingerprint[0...7], expected_fingerprint[7...14], expected_fingerprint[14...21] ]
  end


  let(:hashified_cookbook) do
    KnifeBoxer::HashifiedCookbook.new(File.join(FIXTURES_PATH, "cookbooks/a"), config)
  end
  
  it "has the cookbook's name" do
    expect(hashified_cookbook.name).to eql("a")
  end

  it "generates a fingerprintable text representation of a cookbook" do
    expected_text=<<-E
Name: a
Depends: b ~> 2.1.5
resources/default.rb	d41d8cd98f00b204e9800998ecf8427e
providers/default.rb	d41d8cd98f00b204e9800998ecf8427e
recipes/default.rb	d41d8cd98f00b204e9800998ecf8427e
definitions/definition.rb	d41d8cd98f00b204e9800998ecf8427e
files/default/static-file.txt	d41d8cd98f00b204e9800998ecf8427e
templates/default/config.conf.erb	d41d8cd98f00b204e9800998ecf8427e
metadata.rb	45445750e942f4ff0eff81289beaf269
README.md	4dc5fd07def50ffd2d260076711ff614
E
    expect(hashified_cookbook.fingerprint_text).to eql(expected_text)
  end

  it "generates a fingerprint of a cookbook" do
    expect(hashified_cookbook.fingerprint).to eql(expected_fingerprint)
  end

  it "creates an X.Y.Z version number from the fingerprint" do
    expected = fingerprint_chunks.map {|c| c.to_i(16).to_s }.join(".")
    expect(hashified_cookbook.hashver).to eql(expected)
  end

  it "strips version information from cookbook dependencies" do
    expect(hashified_cookbook.stripped_deps).to eql("b" => ">= 0.0.0")
  end

  it "generates an alternate long description containing the original version number" do
    time = Time.new
    Time.stub!(:new).and_return(time)
    expected=<<-E
Version: 1.2.3
Fingerprint: 45ddfdeaf0811714b0b81b574d19d7a456624a3a
Uploaded by: kallistec
Uploaded at: #{time.utc}
E
    expect(hashified_cookbook.long_desc).to eql(expected)
  end

  it "creates a Chef CookbookVersion modified for hash version numbers" do
    expect(hashified_cookbook.for_upload.version).to eql(hashified_cookbook.hashver)
    expect(hashified_cookbook.for_upload.manifest[:name]).to eql("a-#{hashified_cookbook.hashver}")
    expect(hashified_cookbook.for_upload.metadata.dependencies).to eql(hashified_cookbook.stripped_deps)
    expect(hashified_cookbook.for_upload.metadata.long_description).to eql(hashified_cookbook.long_desc)
    expect(hashified_cookbook.for_upload.manifest[:metadata].long_description).to eql(hashified_cookbook.long_desc)
  end
end
