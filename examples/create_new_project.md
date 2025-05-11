This should feel familiar if you've used Rust's cargo:

Create project dependency
    $ hammer new my_awesome_project

This sets up a basic project structure with a main.c under src/
Feel free to change the folder, so long as you update the yml files under .configuration/


In order to build your binary, Hammer will need to generate the configuration script for 
one of CMake's supported build systems (either use the default, which is Ninja, or specify in compilation_settings.yml

    $ hammer config      # interactive
    $ hammer autoconfig  # no interaction

this will set up a build/ folder where all build artifacts will be placed; if you'd like to have multiple build folders,
or name them in some other name, simply run:

    $ hammer config myBuildFolder
    $ hammer autoconfig myOtherBuildFolder

Once the configuration and generation steps are done, you may move forward to the build step:

    $ hammer build

or if your build folder has a name which is not simply 'build':

    $ hammer build myBuildFolder

If building is succesful, you will find your binary under build/bin/ 


