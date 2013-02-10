require 'chef/search/query'
require 'knife-boxer/constraint_update'

module KnifeBoxer
  class Log < Chef::Knife

    banner "knife log"

    alias :api :rest

    def run
      all_entries = Chef::Search::Query.new.search("cookbook-up-log")[0]
      log_entries = all_entries.sort_by {|e| e["id"] }.reverse
      if ui.stdout.tty?
        write_to_pager(log_entries)
      else
        write_to_stdout(log_entries)
      end
    end

    def write_to_stdout(log_entries)
      log_entries.each { |e| display_entry(ui.stdout, e) }
    rescue Errno::EPIPE
      exit 0
    end

    def write_to_pager(log_entries)
      pager_pid, write = setup_pager
      log_entries.each {|e| display_entry(write, e) }
      write.close
      Process.wait(pager_pid)
    end

    def setup_pager
      read, write = IO.pipe
      write.sync = true
      read.sync = true
      pager_pid = fork do
        write.close
        STDIN.reopen(read)
        IO.select([read], nil, nil, 5)
        exec("less")
      end
      read.close
      [pager_pid, write]
    end

    def display_entry(io, entry)
      io.print(format_entry(entry))
    end

    def format_entry(entry)
      message=<<-E
ID: #{entry["id"]}
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
    end

  end
end
