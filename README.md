# KNIFE BOXER

Knife Boxer provides a set of plugins for managing cookbooks in an
immutable way and creating sandboxed environments for testing.

## Checksum Based Version Numbers

knife boxer uses checksums of cookbook content as the basis for a
cookbook's version number. When uploading cookbooks, you **always**
specify which environment you want to use; knife boxer automatically
updates the version constraints in the environment to match the uploaded
cookbooks. This means that you must go all-in: every node must use
environments, and all of your cookbooks must be uploaded with knife
boxer. Attempting to use the _default environment will result in a node
erratically using different versions of cookbooks because the
checksum-based version numbers don't sort correctly.

## Installation

This is alpha quality code, so it's only distributed via github for now.
Knife only supports a single user plugins directory, so an installation
script is provided to create a shim which will load knife-boxer:

    ruby install.rb

This creates a file `~/.chef/plugins/knife/knife-boxer-shim.rb`. If you
want to uninstall knife-boxer then you need to delete that file.

## Commands

* `knife up ENVIRONMENT COOKBOOK_PATHS`: Upload the cookbooks at the
given paths, and update the environment's constraints to match. You can
also fork a given environment or create a new one.

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

## Errata

There is no way for a knife plugin to atomically mange version
contraints in an environment. Two users uploading at the same time will
stomp each other's changes.

