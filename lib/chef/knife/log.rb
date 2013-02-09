require 'chef/search/query'
require 'knife-boxer/constraint_update'

module KnifeBoxer
  class Log < Chef::Knife

    alias :api :rest

    def run
      all_entries = Chef::Search::Query.new.search("cookbook-up-log")[0]
      log_entries = all_entries.sort_by {|e| e["id"] }.reverse
      log_entries.each {|e| display_entry(e) }
    end

    def display_entry(entry)
      message=<<-E
Environment: #{entry["environment"]}
  Updated by: #{entry["user"]}
  Date: #{Time.at(entry["timestamp"])}

E
      updates = entry["updates"].map do |name, change|
        ConstraintUpdate.new(name, change["old_version"], change["new_version"])
      end
      justify_width = updates.map {|u| u.name.size }.max
      updates.each do |update|
        message << "  #{update.description(justify_width)}\n"
      end
      message << "\n"
      ui.info message
    end

  end
end
