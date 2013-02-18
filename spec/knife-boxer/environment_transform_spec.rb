require 'spec_helper'
require 'knife-boxer/environment_transform'

describe KnifeBoxer::EnvironmentTransform do

  let(:environment) do
    Chef::Environment.new.tap do |e|
      e.name "test"
      e.description("env for rspec test")
      e.default_attributes(foo: "bar")
      e.override_attributes(baz: "quux")
      e.cookbook("foo", "= 777.777.777")
    end
  end

  let(:environment_transform) { KnifeBoxer::EnvironmentTransform.new(environment) }

  context "when first created" do

    it "has an environment" do
      # No reasonable == method on Chef::Environment :(
      expect(environment_transform.environment.name).to eql(environment.name)
      expect(environment_transform.environment.description).to eql(environment.description)
      expect(environment_transform.environment.default_attributes).to eql(environment.default_attributes)
      expect(environment_transform.environment.override_attributes).to eql(environment.override_attributes)
      expect(environment_transform.environment.cookbook_versions).to eql("foo" => "= 777.777.777")
    end

    it "has no cookbooks to upload" do
      expect(environment_transform.cookbooks_to_upload).to eql([])
    end

  end

  context "after updates from a set of cookbooks have been applied" do
    let(:cookbook_on_disk_1) do
      mock("Hashified cookbook 'one'", name: "one", hashver: "111.111.111")
    end

    let(:cookbook_on_disk_2) do
      mock("Hashified cookbook 'two'", name: "two", hashver: "222.222.222")
    end

    let(:cookbooks_to_update) do
      [cookbook_on_disk_1, cookbook_on_disk_2]
    end

    before do
      environment_transform.use_cookbooks(cookbooks_to_update)
    end

    it "sets new version constraints on the environment" do
      expect(environment_transform.environment.cookbook_versions["one"]).to eql("= 111.111.111")
      expect(environment_transform.environment.cookbook_versions["two"]).to eql("= 222.222.222")
    end

    it "calculates a list of updates" do
      expect(environment_transform.updates).to have(2).items
      cb_one_update = environment_transform.updates[0]
      expect(cb_one_update.name).to eql("one")
      expect(cb_one_update.old_version).to eql("Nothing")
      expect(cb_one_update.new_version).to eql("111.111.111")
    end

    it "returns a list of cookbooks to be uploaded" do
      expect(environment_transform.cookbooks_to_upload).to eql(cookbooks_to_update)
    end

    context "and some cookbooks are already up-to-date" do

      let(:environment) do
        Chef::Environment.new.tap do |e|
          e.name "test"
          e.cookbook("one", "= 111.111.111")
          e.cookbook("two", "= 123.123.123")
        end
      end

      it "excludes up to date cookbooks from the list of updates" do
        expect(environment_transform.updates).to have(1).items
        cb_update = environment_transform.updates[0]
        expect(cb_update.name).to eql("two")
        expect(cb_update.old_version).to eql("123.123.123")
        expect(cb_update.new_version).to eql("222.222.222")
      end

      it "excludes up to date cookbooks from the list of cookbooks to upload" do
        expect(environment_transform.cookbooks_to_upload).to eql([cookbook_on_disk_2])
      end

    end

  end

  context "after loading an existing transform" do

    let(:existing_transform_data) do
      # Hash of "cookbook_name" => {"old_version" => "xyz", "new_version" => "xyz prime" }
    end

    it "can reverse itself" do
      pending
      # expect reversed transform to have old and new versions switched.
    end
  end

  # TODO: categorize these
  context "misc behaviors" do

    it "generates a text description" do
      pending
    end

  end

end
