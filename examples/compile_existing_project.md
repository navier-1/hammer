## Using an existing CMakeLists.txt
If you want to use an existing CMakeLists.txt, simply run
the interactive configuration command

    $ hammer config

or, if there is no need for user interaction for the configuration step

    $ hammer autoconfig

## Building with Hammer (ignore existing build files)
If you want to ignore the existing build scripts, or if there are build scripts which are not CMakeLists.txt (hence unsupported by hammer)
you will need to follow this procedure to set up compilation with hammer:

1) Provide the necessary configuration files:
    $ hammer init [PROJECT_DIR]
  or if you're in the dir already, simply:
    $ hammer init

  This will create a .configuration/ directory with the yaml files that describe the project.

2) You will need to edit the configuration files to tell hammer what it needs to look for and where
   it may find it.

   - edit .configuration/sources.yml and add all folders containing source files under globbed_directories.
   In alternative, you may add source files one by one under source_files.

   - if the project has any dependencies, add them under .configuration/dependencies.yml
   Specify the source for them, too. Options are:
   
     - local:  give a specific path on the user machine to include directories and pre-compiled binaries
     - system: give a library name, but no paths, and let the back-end search for it on the system

     - submodule: tell hammer to expect (and setup, if needed) a git submodule remote path of the repo
     TODO: this might be cool as shit to do.

   For more replicable builds, use one of the supported package managers to fetch the dependency.

     - CMake FetchContent/find_package
     - Zig
     - vcpkg
     - Conan

3) Generate the configuration script for your build system of choice with hammer, either interactively 
   or using the default compilation settings which you may find and edit under .configuration/compilation_settings.yml

    $ hammer config --override      # interactive
    $ hammer autoconfig --override  # no interaction

    $ hammer config [BUILD_FOLDER]  # if you feel like naming your build folder; default name is 'build'

   The --override flag tells hammer to ignore the CMakeLists.txt that exists in this folder and to use its own.
   If no CMakeLists.txt is present, you may omit this flag.

4) After running the configuration step you should find a build/ directory set up.
   To build the project:

    $ hammer build [BUILD_FOLDER]


If compilation is succeful, you will find you binary under build/bin/ 



