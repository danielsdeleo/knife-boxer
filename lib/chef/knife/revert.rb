module KnifeBoxer
  class Revert < Chef::Knife

    banner "knife revert UPDATE_ID"

    alias :api :rest

    def run
      unless id_to_revert = name_args.first
        ui.error "Specify an update ID to revert"
        show_usage
        exit 1
      end

      entry_to_revert = load_entry(id_to_revert)
      env_to_revert = api.get("environments/#{entry_to_revert["environment"]}")

      verify_no_conflicts!(env_name, entry_to_revert["updates"])

      transform = EnvironmentTransform.new(env_name, target_versions_by_cookbook)
      transform.apply
      ui.msg "Reverted '#{log_entry.id}'"
      ui.msg "Update id: #{transform.entry_id}"


      reverts = calculate_updates_for(env_to_revert, entry_to_revert)

      #pp reverts
      update_env(env_to_revert, reverts)
      entry = log_reverts(id_to_revert, env_to_revert, reverts)
      env_to_revert.save
      ui.msg "Reverted '#{id_to_revert}'"
      ui.msg "Update id: #{entry.entry_id}"
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

    def update_env(environment, reverts)
      reverts.each do |revert|
        environment.cookbook_versions[revert.name] = revert.new_constraint
      end
    end

    def calculate_updates_for(environment, entry_to_revert)
      reverts = []
      entry_to_revert["updates"].each do |cookbook_name, update_info|
        reverts << ConstraintUpdate.new(cookbook_name, "= #{update_info["new_version"]}" , "= #{update_info["old_version"]}")
      end
      reverts
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
