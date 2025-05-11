## Wait, did anyone actually ask these questions?
Not really, I'm just taking a guess here. Feel free to send me any question, I'll be more than happy to help out and expand this document.


### What if I need to use a specific version of a compiler, at a specific path?
If you need to specify that the compiler should be /my/other/clang instead of what 'which clang' resolves to,
you will have to add it to:
...

Per esempio, su windows voglio specificare che i tool per clang devono essere proprio:
set(CMAKE_C_COMPILER   "C:/Program Files/Microsoft Visual Studio/2022/Enterprise/VC/Tools/Llvm/x64/bin/clang.exe"    CACHE STRING "" FORCE)
set(CMAKE_CXX_COMPILER "C:/Program Files/Microsoft Visual Studio/2022/Enterprise/VC/Tools/Llvm/x64/bin/clang++.exe"  CACHE STRING "" FORCE)
set(CMAKE_LINKER       "C:/Program Files/Microsoft Visual Studio/2022/Enterprise/VC/Tools/Llvm/x64/bin/lld-link.exe" CACHE STRING "" FORCE)

e per la toolchain MSVC:
"C:/Program Files/Microsoft Visual Studio/2022/Enterprise/VC/Tools/MSVC/14.42.34433/bin/Hostx64/x64/cl.exe"
"C:/Program Files/Microsoft Visual Studio/2022/Enterprise/VC/Tools/MSVC/14.42.34433/bin/Hostx64/x64/cl.exe"
"C:/Program Files/Microsoft Visual Studio/2022/Enterprise/VC/Tools/MSVC/14.42.34433/bin/Hostx64/x64/link.exe"

dove lo metto?

### How do I cross-compile?
If at all possible, the best course of action would be to use the zig toolchain.
Just select the Zig toolchain and a compilation profile, and specify the target triplet to use.

*What if I need to pass a linker file?*
*l'integrazione con l'ambito embedded potrebbe essere un bel dito al culo, devo vedere che genere di file*
*devo poter accettare e usare*

### I want to have my project to be cross platform. How can I manage dependencies?
The easiest course of action would be to either use git submodules or a package manager such as vcpkg or conan.

If you would rather not do that and want to manage local depedencies by hand, you will need to essentially replicate
what you have done in the dependencies.yml file for each system.

Your .configuration/ directory should contain:

    win_deps.yml
    linux_deps.yml
    some_other_system_deps.yml

Which should follow the same formatting as the standard dependencies.yml that hammer provides.

Then, when configuring your project on any one of those systems, you may specify which file to use to fetch dependencies as:

    $ hammer config --dependencies path/to/deps_file.yml

You won't need to specify the target OS here; if you are compiling natively, CMake should be able to auto-detect the OS;
if you are cross compiling, that should be handled by the Zig toolchaing when you specify the cross-compilation target in
the configuration step.

### What if I am using a package manager like Zig, CMake FetchContent/find_package, VCPKG or Conan?

[WILL COME BACK TO THIS]
