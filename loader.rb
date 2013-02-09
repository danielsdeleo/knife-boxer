# This loads all of knife-boxer's subcommands. This way you can use
# knife-boxer from a git checkout without stomping on your
# ~/.chef/plugins/knife directory.

glob = File.expand_path("../lib/chef/knife/*rb",__FILE__)
Dir[glob].each {|f| load(f) }
