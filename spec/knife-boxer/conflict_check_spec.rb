require 'spec_helper'
require 'knife-boxer/conflict_check'

describe KnifeBoxer::ConflictCheck do

  let(:environment) do
    Chef::Environment.new.tap do |e|
      e.name("testenv")
      e.cookbook("one", "= 123.456.789")
      e.cookbook("two", "= 987.654.321")
    end
  end

  let(:conflict_check) do
    KnifeBoxer::ConflictCheck.new(environment, changes_to_revert)
  end

  context "when first created" do

    let(:changes_to_revert) { {} }

    it "has an environment" do
      expect(conflict_check.environment).to eql(environment)
    end

    it "has a collection of changes to check for conflicts" do
      expect(conflict_check.changes_to_revert).to eql(changes_to_revert)
    end

    it "has no conflicts" do
      expect(conflict_check.conflicts).to eql([])
    end

  end

  context "when reverting a non-conflicting update" do

    let(:changes_to_revert) do
      { "one" => {"old_version" => "111.111.111", "new_version" => "123.456.789"},
        "two" => {"old_version" => "222.222.222", "new_version" => "987.654.321"} }
    end

    it "has no conflicts" do
      expect(conflict_check.conflicts).to eql([])
    end

  end

  context "when reverting a conflicting update" do
    let(:changes_to_revert) do
      { "one" => {"old_version" => "111.111.111", "new_version" => "555.555.555"},
        "two" => {"old_version" => "Nothing", "new_version" => "987.654.321"} }
    end

    it "has conflicts" do
      expect(conflict_check.conflicts).to_not be_empty
    end

    it "conflicts when the version constraint has been subsequently updated" do
      expected = "Cookbook 'one' conflicts: trying to revert from version '555.555.555' but is '123.456.789'"
      expect(conflict_check.conflicts[0]).to eql(expected)
    end

    it "conflicts when the previous version was not specified" do
      expected = "Cookbook 'two' conflicts: there is no previous version to revert to"
      expect(conflict_check.conflicts[1]).to eql(expected)
    end

  end
end
