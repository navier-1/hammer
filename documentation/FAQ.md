## Wait, did anyone actually ask these questions?
Not really, I'm just taking a guess here. Feel free to send me any question at [tommaso.murolo@gmail.com](mailto:tommaso.murolo@gmail.com), I'll be more than happy to help out and expand this document.

### How do I configure the project?
When you run these commands:

    hammer init [DIR]
    hammer new [DIR]

a '.configure/' directory is creted, which contains the yaml files you'll use for project configuration. These are:

    sources.yml
    dependencies.yml
    settings.yml
    defines.yml

Assuming there is no CMakeLists.txt file in this directory, every time you run these commands:

    hammer config
    hammer autoconfig

the Hammer CLI will compile (transpile) those into a set of .cmake files and place them under .configure/.reserved/

### What if 'hammer config' in a directory with its own CMakeLists.txt?
In that case, that takes precedence over the Hammer-managed configuration.
So running 

    hammer config
will still put you in interactive configuration mode, but using that configuration file.

To use Hammer's own CMakeLists.txt, and hence use your configuration files from .configure/, you will have to run:

    hammer config --override

### What if I don't need an interactive configuration?
If what you specified in the yaml configuration files (or in your own CMakeLists.txt) is enough and you need no interactive configuration:

    hammer autoconfig
    hammer autoconfig --override
are the commands you'll need to use.

### I want to have my project to be cross platform. How can I manage dependencies?
The easiest course of action would probably be to either use git submodules or a package manager such as vcpkg or conan (once they're integrated).

If you would rather not do that and want to manage local depedencies by hand, you will need have a separate dependencies.yml file for each system.
Your .configuration/ directory should contain something like:

    win_deps.yml
    linux_deps.yml

Which should follow the same formatting as the standard dependencies.yml that hammer provides.
Then, when configuring your project on any one of those systems, you may specify which file to use to fetch dependencies as:

    $ hammer config --dependencies deps_file.yml

You won't need to specify the target OS here; if you are compiling natively, CMake should be able to auto-detect the OS;
if you are cross compiling, that should be handled by the Zig toolchaing when you specify the cross-compilation target in
the configuration step.


### What if I need to use a specific version of a compiler, at a specific path?
The default toolchain files that come with this program won't cut it, but a feature will come soon where the user can add specific compilers and linkers to the available toolchains used by Hammer.

### How do I cross-compile?
If at all possible, the best course of action would be to use the zig toolchain.
Just select the Zig toolchain and a compilation profile, and specify the target triplet to use.

But like many other features it's not here yet.

### What if I need to use a linker file?
Stay tuned

### What if I am using a package manager like Zig, CMake FetchContent/find_package, VCPKG or Conan?
Stay tuned
