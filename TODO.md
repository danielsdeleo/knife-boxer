# TODOS:

### GC
This creates an unbounded number of cookbooks, and Chef Server will load
some data about every cookbook when solving the dependency constraints.
Periodic GC is necessary to mitigate the issue.

### env attributes abuse
* stick the x.y.z version number in there
* last modified timestamp
* last modified author

### long description abuse
* stick the original version number in there
* stick the uploader's name in there

### data bag item based history system

* git rev
* git status
* git ls-remote rev?
* optional message
* semantic version number (?)

### "prod mode" (per env):

* require clean git status
* require git ls-remote == git rev-parse (?)
* require "commit" message
