# KNIFE BOXER

Knife Boxer provides a set of plugins for managing cookbooks in an
immutable way and creating sandboxed environments for testing.

## Frictionless Environment Usage

Knife boxer makes environments frictionless. It does this by uploading
cookbooks using version numbers based on checksums of a cookbook's
files. When uploading, you always specify the environment you want the
cookbooks to apply to:

    knife up production cookbooks/redis

This uploads the cookbook with a version number like
"30718453.4494255.188737193" and pins the production environment to this
version. You never need to worry about overwriting this cookbook with a
development version, because the version number is computed from the
cookbook content.

This has a few implications:

1. You have to use environments everywhere. The "_default" environment
   is basically useless if you use this plugin.
2. Your team has to go all-in. This only works if everyone uses it.
3. Version information is stripped from cookbook dependencies, so the
   Chef server can't solve constraints for you. You need to have an
   interoperable set of cookbooks on disk to upload.

In this scheme, version numbers have no relationship to the amount of
change in a cookbook or when it was written. To make this easier to
handle, each cookbook upload writes a log entry in a data bag. You can
search this data bag by environment, cookbook, or username to see what's
changed in your cookbooks and environments.

Knife boxer also makes it easy to create disposable environments the
same way you'd use git branches for development or exploration. When
uploading you can choose to create a new environment or fork an existing
one so that your changes are isolated from other environments. For
example, to create a "my-hacks" environment which is copied from
production with your own edits to the application cookbook:

    knife up -f production my-hacks cookbooks/application

## Commands

* `knife up ENVIRONMENT COOKBOOK_PATHS`: Upload the cookbooks at the
given paths, and update the environment's constraints to match. You can
also fork a given environment or create a new one.

* `knife log`: Display logs generated by `knife up`. Logs are stored as
data bag items and fetched by search, so there is a delay between
writing them and when they are available. This is very prototype-y.
Filtering features are planned but not implemented.

## Installation

This is alpha quality code, so it's only distributed via github for now.
Knife only supports a single user plugins directory, so an installation
script is provided to create a shim which will load knife-boxer:

    ruby install.rb

This creates a file `~/.chef/plugins/knife/knife-boxer-shim.rb`. If you
want to uninstall knife-boxer then you need to delete that file.

## Project Goals

This plugin implements as much of [my ideal conception of environments](https://gist.github.com/danielsdeleo/7c55ebe39639928134df)
as is possible without server modifications.

1. Frictionless environments: I want environments to work without
   a bump a version here, change a dependency there dance.
2. Integrated freezing: Related to the above, I don't want to do any
   extra work to ensure that no one stomps an existing cookbook version.
3. Move responsibility for solving cookbook constraints elsewhere: I
   don't need the Chef server to solve the dependency constraints of my
   cookbooks every time chef-client asks for cookbooks. This can be done
   in a different time/place, e.g., with librarian or berkshelf.

## About the Name

* I have a boxer dog. She's awesome.
* The default environments workflow makes me want to punch someone in
  the face.
* Lightweight environment "forking" means everyone on the team can have
  their own sandboxes to test changes with whatever degree of isolation
  is appropriate.


## Errata

There is no way for a knife plugin to atomically mange version
contraints in an environment. Two users uploading at the same time will
stomp each other's changes.

