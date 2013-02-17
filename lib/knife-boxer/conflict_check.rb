module KnifeBoxer
  class ConflictCheck

    # A Chef::Environment. This environment's version constraints will be
    # checked for conflicts to determine if a set of changes can be reverted.
    attr_reader :environment

    # A Hash of the form
    #   cookbook_name<String> => { "old_version" => version<String>, "new_version" => version<String> }
    # This hash describes the change that the user wants to revert.
    attr_reader :changes_to_revert

    def initialize(environment, changes_to_revert)
      @environment = environment
      @changes_to_revert = changes_to_revert
    end

    # An Array of messages describing conflicts that prevent the change from
    # being reverted.
    def conflicts
      conflicted_changes = []
      changes_to_revert.each do |cookbook_name, update_info|
        expected_version = update_info["new_version"]
        actual_version = environment.cookbook_versions[cookbook_name].sub(/^= /, '')

        # conflict checks; if versions have since been updated, or
        # old_version is "Nothing" we bail.
        if actual_version != expected_version
          conflicted_changes << "Cookbook '#{cookbook_name}' conflicts: trying to revert from version '#{expected_version}' but is '#{actual_version}'"
          next
        elsif update_info["old_version"] == "Nothing"
          conflicted_changes << "Cookbook '#{cookbook_name}' conflicts: there is no previous version to revert to"
          next
        end
      end
      conflicted_changes
    end

  end
end
