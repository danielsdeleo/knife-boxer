module KnifeBoxer
  class Revert < Chef::Knife

    deps do
      require 'knife-boxer/environment_transform'
      require 'knife-boxer/conflict_check'
      require 'knife-boxer/log_entry'
    end

    banner "knife revert UPDATE_ID"

    alias :api :rest

    # Chef::Environment to be updated
    attr_reader :environment

    attr_reader :log_entry

    attr_reader :changes_to_revert

    def run
      process_args

      verify_no_conflicts!(environment, changes_to_revert)

      transform = EnvironmentTransform.new(environment)
      transform.revert(changes_to_revert)
      transform.environment.save
      revert_entry = log_reverts(log_entry["id"], environment, transform.updates)
      ui.msg "Reverted '#{log_entry["id"]}'"
      ui.msg "Update id: #{revert_entry.entry_id}"
      ui.msg(transform.description)
    end

    def process_args
      unless id_to_revert = name_args.first
        ui.error "Specify an update ID to revert"
        show_usage
        exit 1
      end

      @log_entry = load_entry(id_to_revert)
      @changes_to_revert = log_entry["updates"]
      @environment = api.get("environments/#{log_entry["environment"]}")
    end

    def verify_no_conflicts!(environment, changes_to_revert)
      checker = ConflictCheck.new(environment, changes_to_revert)
      unless checker.conflicts.empty?
        ui.error "Failed to revert because of conflicts"
        checker.conflicts.each {|c| ui.msg c }
        exit 1
      end
    end

    def log_reverts(reverted_id, env, reverts)
      entry = LogEntry.new(Chef::Config) do |e|
        e.environment = env.name
        e.constraint_updates = reverts
        e.message = "Revert '#{reverted_id}'"
      end
      entry.write
      entry
    end

    def load_entry(entry_id)
      api.get("data/cookbook-up-log/#{entry_id}")
      # TODO: rescue not found, error out.
    rescue Net::HTTPServerException => e
      raise unless e.response.code.to_s == "404"
      ui.error "Update id '#{entry_id}' could not be found"
      ui.msg "Use `knife log` to view update logs"
      exit 1
    end

  end
end

