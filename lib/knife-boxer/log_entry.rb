require 'time'
require 'chef/rest'
require 'chef/data_bag'
require 'chef/data_bag_item'

module KnifeBoxer
  class LogEntry

    attr_accessor :user
    attr_accessor :message
    attr_accessor :constraint_updates
    attr_accessor :environment

    def initialize(config)
      @user = config[:node_name]
      @time = Time.new.utc
      @environment = ""
      @constraint_updates = []
      @message = "(No message)"
      yield self if block_given?
    end

    def entry_id
      @time.strftime("%Y%m%d%H%M%S")
    end

    def timestamp
      @time.to_i
    end

    def datetime
      @time.iso8601
    end

    def updated_cookbooks
      constraint_updates.inject({}) do |update_map, update|
        update_map[update.name] = {
          "old_version" => update.old_version,
          "new_version" => update.new_version
        }
        update_map
      end
    end

    def to_data_item
      item = Chef::DataBagItem.new
      item.data_bag("cookbook-up-log")
      item.raw_data = {"id" => entry_id,
                       "timestamp" => timestamp,
                       "datetime" => datetime,
                       "user" => user,
                       "environment" => environment,
                       "message" => message,
                       "updates" => updated_cookbooks
      }
      item
    end

    def write
      api.post("data/cookbook-up-log", to_data_item)
    rescue Net::HTTPServerException => e
      if e.response.code.to_s == "404"
        create_log_data_bag
        retry
      end
    end

    def create_log_data_bag
      bag = Chef::DataBag.new.tap {|b| b.name("cookbook-up-log") }
      api.post("data", bag)
    end

    def api
      Chef::REST.new(Chef::Config[:chef_server_url])
    end

  end
end
