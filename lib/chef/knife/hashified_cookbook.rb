require 'digest'

module KnifeBoxer
  class HashifiedCookbook

    attr_reader :cookbook_version

    def initialize(cookbook_loader)
      cookbook_loader.load_cookbooks

      @cookbook_version = cookbook_loader.cookbook_version
    end

    def name
      cookbook_version.name
    end

    def hash_text
      metatext = "Name: #{name}\n"

      cookbook_version.metadata.dependencies.to_a.sort.each do |dep_cookbook, version|
        metatext << "Depends: #{dep_cookbook} #{version}\n"
      end

      cookbook_version.manifest_records_by_path.to_a.sort_by {|a,b| a[0] <=> b[0]}.each do |path, info|
        metatext << "#{path}\t#{info["checksum"]}\n"
      end

      metatext
    end

    def cookbook_cksum
      Digest::SHA1.hexdigest(hash_text)
    end

    def hashver
      cksum = cookbook_cksum

      # NOTE: Chef servers using SQL have a signed 'integer' field for version
      # numbers, max of 31 bits (2,147,483,647 in base 10). 8 hex digits is too
      # many, but 7 will fit (268,435,455 in base 10). Truncating the checksum
      # is probably wrong in ways that I don't even know about, but there's no
      # way to fit the information we want in the size we have.

      major = cksum[0...7].to_i(16).to_s
      minor = cksum[7...14].to_i(16).to_s
      patch = cksum[14...21].to_i(16).to_s

      "#{major}.#{minor}.#{patch}"
    end

    def cbv_for_upload
      cbv = cookbook_version.dup
      cbv.version = hashver
      cbv.manifest[:name] = "#{name}-#{hashver}"
      cbv.metadata = cbv.metadata.dup

      # Nuke version constraints from the uploaded cookbook. We're going
      # whole-hog on pinning every cookbook in an environment, and we're also
      # mangling cookbook's version numbers, so we can't rely on the version
      # constraints in the cookbooks not breaking our hash-version scheme.
      #
      # FIXME: This also probably mutates the original cookbook's dependencies
      # hash; there's no way to replace it with a dup. Find a workaround.
      cbv.metadata.dependencies.keys.each do |dep|
        cbv.metadata.dependencies[dep] = ">= 0.0.0"
      end

      cbv
    end

  end
end
