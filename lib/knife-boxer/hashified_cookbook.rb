require 'digest'

# TODO: this is a bug in Chef, CookbookVersion requires 'chef/node'
# unnecessarily which leads to death in circular requires.
# We have no actual use for chef/resource
require 'chef/resource'
require 'chef/cookbook/cookbook_version_loader'

# TODO: also a Chef bug, CookbookVersion uses Chef::Digester but doesn't
# require it
require 'chef/digester'

require 'chef/cookbook/metadata'

module KnifeBoxer

  # === HashifiedCookbook
  # This class is essentially a wrapper for Chef's
  # CookbookVersionLoader.
  class HashifiedCookbook

    DEFAULT_VERSION_CONSTRAINT = ">= 0.0.0".freeze

    attr_reader :path
    attr_reader :config

    def initialize(path, config)
      @path = File.expand_path(path)
      @config = config
    end

    def cookbook_version_loader
      @cookbook_version_loader ||= begin
        cb_loader = Chef::Cookbook::CookbookVersionLoader.new(path)
        cb_loader.load_cookbooks
        cb_loader
      end
    end

    def cookbook_version
      @cookbook_version = cookbook_version_loader.cookbook_version
    end

    # The cookbook's name
    def name
      cookbook_version.name.to_s
    end

    # Generates a String describing the cookbook's content, including
    # checksums of individual files. This string should be completely
    # deterministic based on file content so it can be used to generate
    # a fingerprint of the entire cookbook.
    def fingerprint_text
      @fingerprint_text ||= begin
        metatext = "Name: #{name}\n"

        cookbook_version.metadata.dependencies.to_a.sort.each do |dep_cookbook, version|
          metatext << "Depends: #{dep_cookbook} #{version}\n"
        end

        cookbook_version.manifest_records_by_path.to_a.sort_by {|a,b| a[0] <=> b[0]}.each do |path, info|
          metatext << "#{path}\t#{info["checksum"]}\n"
        end

        metatext
      end
    end

    # Generates a SHA1 hash of the fingerprint_text, which is unique to
    # the content of the cookbook.
    def fingerprint
      @fingerprint ||= Digest::SHA1.hexdigest(fingerprint_text)
    end

    # Generates an x.y.z version number based on the cookbook's
    # fingerprint. There are a few constraints on cookbook version
    # numbers that need to be met. Firstly, version numbers are base 10
    # and not hex. Secondly, current versions of Chef server store
    # cookbook's version numbers as a SQL signed integer, which has a
    # maximum value of 31 bits (2,147,483,647 in base 10). To fit this
    # restriction, we take the first 3 blocks of 7 hex digits in the
    # fingerprint, convert them to base 10, and use these for the major,
    # minor, and patch versions respectively. This means that only 84
    # bits of the 140 bit SHA 1 are used.
    def hashver
      major = fingerprint[0...7].to_i(16).to_s
      minor = fingerprint[7...14].to_i(16).to_s
      patch = fingerprint[14...21].to_i(16).to_s

      "#{major}.#{minor}.#{patch}"
    end

    # Generates a copy of the cookbook's dependencies with all version
    # constraints set to ">= 0.0.0". Since knife boxer always pins all
    # cookbooks to exact equality in an environment, there's no use in
    # setting version constraints in a cookbook's dependencies, and it
    # wouldn't work with the checksum based version numbers anyway.
    def stripped_deps
      cookbook_version.metadata.dependencies.keys.inject({}) do |stripped_dep_map, dep|
        stripped_dep_map[dep] = DEFAULT_VERSION_CONSTRAINT
        stripped_dep_map
      end
    end

    def long_desc
      <<-E
Version: #{cookbook_version.version}
Fingerprint: #{fingerprint}
Uploaded by: #{config[:node_name]}
Uploaded at: #{Time.new.utc}
E
    end

    # Returns a Chef CookbookVersion object based on the on-disk
    # cookbook but with version numbers and dependencies modified to use
    # the checksum-based version number scheme.
    def for_upload
      cbv = cookbook_version.dup
      cbv.version = hashver
      cbv.manifest[:name] = "#{name}-#{hashver}"
      new_metadata = Chef::Cookbook::Metadata.new.tap do |m|
        m.name(name)
        m.version(hashver)
        m.long_description(long_desc)
        m.dependencies.merge!(stripped_deps)
      end

      cbv.metadata = new_metadata
      cbv
    end

  end
end
