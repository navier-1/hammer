## Creating the repo
This should feel familiar if you've used Rust's cargo:

Create project repo
    $ hammer new my_awesome_proj

This sets up this basic project structure:

my_awsome_proj/
    include/
    src/
        main.c
    .configure/
        sources.yml
        dependencies.yml
        defines.yml
        settings.yml

The directory that contains the configuration of the project is, unsurprisingly, .configuration/
The layout of the project can be specified under the sources.yml (more on this in that file's guide).


## Configuring the build
The build script configuration and generation is performed using CMake; Hammer comes with a default
CMakeLists.txt in the back-end, so it does not need to be copied to your project.

To configure the build with Hammer (i.e. get it to call its CMakeLists.txt) the command is:

    $ hammer config      # GUI/TUI interactive configuration
    $ hammer autoconfig  # no interaction

This uses the default values for the build:
  - Ninja as build system
  - clang compiler
  - lld linker

If you want to change the compiler / linker, check out the guide on toolchains.
If you want to select the build system, pass the flag exactly as you would for CMake, e.g.:

    $ hammer config -G "Unix Makefiles"


The configuration step will set up a build/ folder at the top level for the build artifacts; 
if you'd like to have multiple build folders, or name them with some other name, simply run:

    $ hammer config myBuildFolder
    $ hammer autoconfig myOtherBuildFolder

If there any any CMake-specific flags you want to add, freely add them in the CLI command and they will be relayed:

    $ hammer config --no-warn-unused-cli
    $ hammer config OtherBuild --no-warn-unused-cli

## Building the project
Once the configuration and generation steps are done, you may move forward to the build step:

    $ hammer build

or if your build folder has a name which is not simply 'build':

    $ hammer build myBuildFolder

Like for configuration, you may add any further inputs for the build system.
For example, if you selected Unix Makefiles as build system, you may run a parallel build like so:

    $ hammer config -j16
    $ hammer config thatOtherBuild -j16

If building is succesful, you will find your binary under build/bin/



