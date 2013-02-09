require 'pp'

require 'knife-boxer/hashified_cookbook'
require 'knife-boxer/constraint_update'
require 'knife-boxer/log_entry'

module KnifeBoxer

  class Up < Chef::Knife


    alias :api :rest

    deps do
      require 'chef/cookbook_uploader'
    end

    banner "knife up ENVIRONMENT COOKBOOK_PATH [COOKBOOK_PATH ...]"

    option :create_env,
      short: "-C",
      long: "--create-env",
      description: "create ENVIRONMENT if it doesn't exist",
      boolean: true,
      default: false

    option :fork_env,
      short: "-f BASE_ENVIRONMENT",
      long: "--fork-env BASE_ENVIRONMENT",
      description: "fork the environment BASE_ENVIRONMENT, then upload to it"

    attr_reader :env_updates

    def run
      if name_args.empty? or name_args.size < 2
        show_usage
        exit 1
      end

      @env_updates = []

      env_and_paths = name_args.dup
      env_name = env_and_paths.shift
      input_paths = env_and_paths

      environment = fetch_or_build_env(env_name)
      cookbook_paths = expand_and_filter_paths(input_paths)
      hashified_cookbooks = cookbook_paths.map {|path| hashify_cookbook(path) }

      update_env(environment, hashified_cookbooks)
      if no_updates?
        ui.msg "All cookbooks up to date in #{env_name}"
        exit 0
      end
      show_updates
      upload_cookbooks

      write_log_entry(env_name)

      save_env(environment)
    end

    def write_log_entry(env_name)
      entry = LogEntry.new do |e|
        e.environment = env_name
        e.constraint_updates = env_updates
      end
      entry.write
    end

    def upload_cookbooks
      cookbooks_for_upload = env_updates.map do |u|
        u.cb.for_upload
      end

      uploader = Chef::CookbookUploader.new(cookbooks_for_upload, nil)
      uploader.upload_cookbooks
    end

    def no_updates?
      env_updates.empty?
    end

    def show_updates
      justify_width = env_updates.map {|u| u.name.size }.max
      env_updates.each do |update|
        ui.info(update.description(justify_width))
      end
    end

    def update_env(environment, hashified_cookbooks)
      hashified_cookbooks.each do |cb|
        old_constraint = environment.cookbook_versions[cb.name.to_s]
        new_constraint = "= #{cb.hashver}"

        if old_constraint != new_constraint
          environment.cookbook_versions[cb.name.to_s] = new_constraint
          @env_updates << ConstraintUpdate.new(cb.name, old_constraint, new_constraint)
        end
      end
    end

    def fetch_or_build_env(name)
      # TODO: assert env doesn't exist for create/fork
      # TODO: rescue 404 and suggest -C option for update case
      if config[:create_env]
        Chef::Environment.new.tap {|e| e.name(name) }
      elsif config[:fork_env]
        api.get("environments/#{config[:fork_env]}").tap {|e| e.name(name) }
      else
        api.get("environments/#{name}")
      end
    end

    def save_env(env)
      if config[:create_env] or config[:fork_env]
        api.post("environments", env)
      else
        api.put("environments/#{env.name}", env)
      end
    end

    def expand_and_filter_paths(maybe_cookbook_paths)
      expanded_paths = maybe_cookbook_paths.map {|p| File.expand_path(p) }
      expanded_paths.select {|p| File.directory?(p) }
    end

    def hashify_cookbook(path)
      HashifiedCookbook.new(path, config)
    end

  end

end



