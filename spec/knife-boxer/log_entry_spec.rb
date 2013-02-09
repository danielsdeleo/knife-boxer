require 'spec_helper'
require 'knife-boxer/log_entry'
require 'knife-boxer/constraint_update'

describe KnifeBoxer::LogEntry do

  # Eagerly evaluate to avoid order of operations issue when stubbing
  # time.new
  let!(:now) { Time.new }

  let(:config) do
    { node_name: "kallistec" }
  end

  let(:constraint_updates) do
    [KnifeBoxer::ConstraintUpdate.new("application", "= 123.456.789", "= 987.654.321")]
  end

  let(:log_entry) do
    Time.stub!(:new).and_return(now)
    KnifeBoxer::LogEntry.new(config) do |e|
      e.environment = "production"
      e.message = "Updating app cookbook for new release"
      e.constraint_updates = constraint_updates
    end
  end

  it "has an environment" do
    expect(log_entry.environment).to eql("production")
  end

  it "generates an entry id based on the time" do
    expect(log_entry.entry_id).to eql(now.strftime("%Y%m%d%H%M%S"))
  end

  it "generates a timestamp in Unix time format" do
    expect(log_entry.timestamp).to eql(now.to_i)
  end

  it "generates a datetime as a string" do
    expect(log_entry.datetime).to eql(now.iso8601)
  end

  it "has a map of cookbook updates" do
    expected = {"application" => {"old_version" => "123.456.789", "new_version" => "987.654.321"}}
    expect(log_entry.updated_cookbooks).to eql(expected)
  end

  it "converts to a data bag item" do
    pending
  end

  it "creates a data bag item" do
    pending
  end

  it "creates the data bag for log entries if required" do
    pending
  end
end
