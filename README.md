## Overview
Hammer is a portable and user-friendly set of tools to manage C and C++ projects.

It's a hacky attempt to provide a compact CLI a-la Cargo (Rust's build tool) to configure C/C++ projects
on Linux and Windows, with provided integrations to several development tools that
one would otherwise have to integrate on their own. 

The base idea is to try and decouple as much as possible the source code from how it is built;
to simply have a tool that can take care of compilation of a wide number of projects easily.
  The tool should be simple enough for the developer to pick up without having to worry about
knowing any CMake or other build tools.


This is much like what the [Zig](https://ziglang.org) project is striving for with its incredible toolchain.
Using CMake currently simplifies legacy support and modularity (e.g. by allowing for multiple compilers).

### Features

* CLI utilities to setup, configure and build new and existing projects
* Build targets are configured via YAML files
* Support for multiple compilers, linkers and build systems
  (at some point, a feature will be added to allow simple addition of 
  new toolchain files so that one may use hammer with any compiler and linker they prefer)


### Tools involved

* The back-end uses [CMake](https://cmake.org) for configuration.
This is what does most of the heavy lifting, and allows the entire thing to be cross platform and support
multiple buildsystems such as GNU Make, Ninja, Visual Studio...

* The front-end CLI the user interacts with is written in [Zig](https://ziglang.org/); other than being a great
language it comes with an amazing toolchain, which allows for easy cross-compilation to a wide set of targets.

* When configuring the project, the CLI calls on graphical configuration programs that are built for CMake: 
[ccmake](https://cmake.org/cmake/help/latest/manual/ccmake.1.html) on Linux, [cmake-gui](https://cmake.org/cmake/help/latest/manual/cmake-gui.1.html) on Windows;

* Some integration with useful tools for development are provided. For example:
  - test coverage support
  - static analysis
  - [TBD]linting

* [TBD] Integration with common C and C++ package managers such as [VCPKG](https://vcpkg.io/en/) and [Conan](https://conan.io/)


All Hammer is, at the end of the day, is a collection of freely accessible tools and frameworks, packaged in a way that 
makes them hopefully more convenient to use.

However, in places where a choice had to be made between control and convenience, control was always favored.
the goal is to make the developer feel that using Hammer as a build assistant gives them no less knowledge or
control over the project than they would have had with some other tool.

## Design
The user interacts with a front-end CLI that takes heavy inspiration from Rust's Cargo.
It provides a few quick commands to organize a project:

   $ hammer config
   $ hammer build
   $ hammer docs

Here is a quick snippet into how to go about creating a new project with hammer:

    $ hammer new myproject

## Modularity
The tool is meant to be as portable and customizeable as possible.

Don't want to use a feature? Just throw out the related folder,
and avoid selecting the associated option when configuring a project.

A provided functionality sucks and yours is better? Simply swap out 
the implementation and it all works as before.

## Installation

### Linux
    $ sudo ./install_hammer.sh

### Windows
    > powershell -ExecutionPolicy Bypass -File .\winstall.ps1

### MacOS
I don't use it and have no knowledge of how to port it, but if any macOS user feels like it would
be useful for them and wants to send code I'd love to accept it.

## Packages
Hammer comes with support for integration of several tools, such as testing frameworks and
static code analysis tools. The package system is so bare-bones it barely
classifies as such; all it is, really, is a ready-made collection of bash scripts
that are meant for the user to quickly fetch a dependency without fighting too much
with their system in order to start using it.

e.g.

    $ hammer install codeql

And that's it, the script starts and you're ready to go.

Each installation script comes with an associated uninstall script,
which the user can simply run with

    $ hammer uninstall codeql

And if you get tired of using hammer? Tell it to off itself.

    $ hammer uninstall hammer

## Getting started

A quick guide to writing your first C/C++ program with hammer.

You are going to need to have CMake installed, as well as the graphical 
support to CMake which is

- ccmake on Linux
- cmake-gui on Windows


### Create a repo
    $ hammer new MyAwesomeRepo
    $ cd MyAwesomeRepo

### Adding sources
    You can add your own .c/.cpp files under src/ and your .h/.hpp files under include/.
    Alternatively, you can simply go with the default main.c that comes under src/.

### Configuring the project
    You will need to have ccmake (Linux) / cmake-gui (Windows) installed for this step, so make sure you have it.

    $ hammer config

    Enable, disable and edit any configuration parameter you please. You may toggle the advanced
    options to display all the options which are hidden by default.

    You'll need to configure and generate a Makefile/Ninjafile/other (knowledge of CMake comes in handy here)

    All build artifacts so far and those coming later are stored under a default build/ directory;
    when configuring one may specify their desired build dir or generator by going

    $ hammer config -B buildHere -G "Ninja"

    (again, the CMake user will find this familiar)

### Building the project
    Fairly straight-up:

    $ hammer build              # default build/ directory
    $ hammer build buildHere    #  chosen build directory

### Check the binary
    You'll find your emitted binaries under build/bin/
    If what you configured is an executable (as per default), you may simply run it with:

    $ hammer run
    $ hammer run buildHere

## Project structure

Hammer is divided in a C++ front-end (the CLI binary that the user runs) and a collection of CMake and Bash scripts
in the back-end that get selectively invoked by the front-end.

### Front end
Some poorly written code that provides the typical collection of commands and help messages you'd expect.
If you take a look at the commands that it launches, you may as well delete it and re-write it yourself, keeping
the back-end (which is what does all the heavy work anyways).

The yaml files used to configure the hammer project get parsed to emit some equivalent .cmake files for the back-end.

### Back end
[All the interesting things]

## Going from here
  There's really nothing new under the sun here. Hammer is just packaging some scripts and utilities, check out
  what it has available by running 

    $ hammer help

  and see if any of the available features and packages interest you.

  If you find this tool of any help, you will no doubt find many many issues with it. I am a lone developer
  and have thrown many parts of this project on the board just to get it running.

  Any comment, suggestion, request and especially code are very much appreciated!

  If you do end up adding functionality to your own version of this project, kindly consider sharing it with everyone else.



