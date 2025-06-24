## Subprojects

Consider you want to break up your repo in individual sub-projects.

my_repo/
    foo/
        ...
    bar/
        ...
    baz/
        ...


What you could do is initialize every standalone project using hammer init.
Either pass the relative path to the directories like so:

    $ hammer init foo
    $ hammer init bar
    $ hammer init baz

or cd into each one and run
    $ hammer init

Now each of those will have a .configuration/ directory containing the yaml configuration.

Each subproject can be built individually, by going anywhere under their root dir and running:

    ### No interaction
    $ hammer autoconfig
    $ hammer build
or
    ### Interactive configuration
    $ hammer config
    $ hammer build


If you want to build all of them from the top level dir:

    $ hammer build-all





