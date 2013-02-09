require 'chef/search/query'

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
      entry["updates"].each do |cookbook, change|
        message << "  #{cookbook} #{change["old_version"]} => #{change["new_version"]}\n"
      end
      message << "\n"
      ui.info message
    end

  end
end
