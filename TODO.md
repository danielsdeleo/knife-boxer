# TODOS:

### GC
This creates an unbounded number of cookbooks, and Chef Server will load
some data about every cookbook when solving the dependency constraints.
Periodic GC is necessary to mitigate the issue.

### Revert
Given an update ID, revert to old versions.

### env attributes abuse
* stick the x.y.z version number in there
* last modified timestamp
* last modified author

### data bag item based history system
This exists, it just needs git integration.

* Show log message in `knife log`

* git rev
* git status
* git ls-remote rev?
* optional message
* semantic version number (?)

### "prod mode" (per env):

* require clean git status
* require git ls-remote == git rev-parse (?)
* require "commit" message
