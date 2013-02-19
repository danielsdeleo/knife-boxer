require 'chef/environment'
require 'knife-boxer/constraint_update'
require 'knife-boxer/log_entry'
require 'knife-boxer/environment_transform'

module KnifeBoxer
  class EnvironmentTransform

    attr_reader :updates

    # The Chef::Environment object being transformed.
    attr_reader :environment

    # An Array of cookbooks to upload. This is only populated when transforming
    # an environment via cookbook uploads.
    attr_reader :cookbooks_to_upload

    def initialize(environment)
      @environment = clone_environment(environment)
      @updates = []
      @cookbooks_to_upload = []
    end

    # Iterates over the list of +candidate_uploads+ and checks their versions
    # against the versions in the environment. If the version of the cookbook
    # in the candidate list != the version in the environment, the cookbook is
    # added to the list of updates the cookbook is added to the list of
    # cookbooks_to_upload and the desired change recorded in the updates list.
    def use_cookbooks(candidate_uploads)
      candidate_uploads.each do |cb|
        old_constraint = constraints[cb.name]
        new_constraint = "= #{cb.hashver}"

        if old_constraint != new_constraint
          constraints[cb.name] = new_constraint
          updates << ConstraintUpdate.new(cb.name, old_constraint, new_constraint)
          cookbooks_to_upload << cb
        end
      end
    end

    # Takes a Hash of the form:
    #   cookbook_name<String> => { "old_version" => old_version<String>, "new_version" => new_version<String> }
    # Applies a revert to the environment by setting constraints to the old
    # versions. It's the caller's responsibility to check for conflicts first.
    def revert(updates_by_cookbook)
      updates_by_cookbook.each do |cookbook_name, update_info|
        old_constraint = constraints[cookbook_name]
        new_constraint = "= #{update_info["old_version"]}"

        if old_constraint != new_constraint
          constraints[cookbook_name] = new_constraint
          updates << ConstraintUpdate.new(cookbook_name, old_constraint, new_constraint)
        end
      end
    end

    # true if there are updates for the environment, false otherwise.
    def updates_required?
      !updates.empty?
    end

    def update_count
      updates.size
    end

    def description
      justify_width = updates.map {|u| u.name.size }.max
      updates.inject("") do |desc, update|
        desc << update.description(justify_width) << "\n"
      end
    end

    # Delegate method for the environment's cookbook versions.
    def constraints
      environment.cookbook_versions
    end

    private

    # Creates a new environment with the same attributes as +environment+.
    # The cookbook_versions variable is deep cloned so it can be modified
    # safely.
    def clone_environment(environment)
      Chef::Environment.new.tap do |e|
        # We don't intend to modify these so we don't deep clone them:
        e.name(environment.name)
        e.description(environment.description)
        e.default_attributes = environment.default_attributes
        e.override_attributes = environment.override_attributes
        # cookbook_versions will be modified so we deep clone:
        e.cookbook_versions(environment.cookbook_versions.dup)
      end
    end

  end
end

