
module KnifeBoxer

  class Up < Chef::Knife

    alias :api :rest

    deps do
      require 'chef/cookbook_uploader'
      require 'knife-boxer/hashified_cookbook'
      require 'knife-boxer/constraint_update'
      require 'knife-boxer/log_entry'
      require 'knife-boxer/environment_transform'
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

    # paths to cookbooks to upload
    attr_reader :cookbook_paths

    # Chef::Environment to be updated
    attr_reader :environment

    def run
      if name_args.empty? or name_args.size < 2
        show_usage
        exit 1
      end

      process_args

      unless transform.updates_required?
        ui.msg "All cookbooks up to date in #{env_name}"
        exit 0
      end


      ui.msg("Uploading #{transform.update_count} cookbook(s)")
      upload_cookbooks

      log_entry = write_log_entry
      ui.msg "update id: #{log_entry.entry_id}"
      ui.msg(transform.description)

      save_environment
    end

    def process_args
      env_and_paths = name_args.dup
      env_name = env_and_paths.shift
      input_paths = env_and_paths

      @environment = fetch_or_build_env(env_name)
      @cookbook_paths = expand_and_filter_paths(input_paths)
    end

    def environment_name
      environment.name
    end

    def updates
      transform.updates
    end

    def wrapped_cookbooks
      @wrapped_cookbooks ||= begin
        cookbook_paths.inject({}) do |by_name, path|
          wrapper = hashify_cookbook(path)
          by_name[wrapper.name] = wrapper
          by_name
        end
      end
    end

    def transform
      @transform ||= begin
        t = EnvironmentTransform.new(environment)
        t.use_cookbooks(wrapped_cookbooks.values)
        t
      end
    end


    def write_log_entry
      entry = LogEntry.new(Chef::Config) do |e|
        e.environment = environment_name
        e.constraint_updates = updates
      end
      entry.write
      entry
    end

    def upload_cookbooks
      cookbooks_for_upload = updates.map do |u|
        wrapped_cookbooks[u.name].for_upload
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

    def save_environment
      if config[:create_env] or config[:fork_env]
        api.post("environments", environment)
      else
        api.put("environments/#{env.name}", environment)
      end
    end

    def expand_and_filter_paths(maybe_cookbook_paths)
      expanded_paths = maybe_cookbook_paths.map {|p| File.expand_path(p) }
      expanded_paths.select {|p| File.directory?(p) }
    end

    def hashify_cookbook(path)
      HashifiedCookbook.new(path, Chef::Config)
    end

  end

end



