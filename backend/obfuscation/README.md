# anti-reversing-template

Template to use for making C software harder to reverse-engineer.

Key steps:

- Use _forceinline_ for the sensible code, putting both declaration and definition in the header file.
- Define a _junkle_ function for each function to obfuscate, following the example: the _junkle_ function must have the same prototype. Inside the function, there will be calls to an inline function called _generic_junk_, adjust the call parameters in order to generate junk code that use function parameters.
- Use the _junkle_ wrapper instead of the target functions.
- Enable the Linker->Debugging option "Generate Map File" (Visual Studio), to use the map file to find address and size of the function to encrypt in the Python script; for Clang, go to "Linker->Command Line->Additional Options" and add `/MAP:$(OutDir)anti_reversing_template.map`.
- There is the implementation of **License Sealing** in _junkle_ functions. Suppose we require each function to have a `char* license` parameter. In each _junkle_ function, there is the computation of the FNV1a-32 hash of the license, and then the XOR with a value, such that the result is a fixed value that makes sure that branches lead to the target function. Since the license may change, the XOR value is not fixed, but is instead the placeholder `0xdeadbeef`, that gets patched in post-build, according to the given license key for which the binary must be generated. In "Configuration Properties"->Debugging it's possible to set the license key as command-line argument.
- Define a _s_operation_ function for each _junkle_ wrapper, for example _s_encrypt_; this will be responsible for runtime decryption and execution, using OS-specific (both for Windows and Linux/MacOS) mapping functions to temporarily change page permissions to RWX (if RWX is a problem for the OS, it can be used the approach of allocating a new RW page and then turning the page to RX after writing the decrypted code to it, and call that with function pointer instead of directly calling the program's function). Each _s_operation_ will have the same prototype of the corresponding _junkle_ wrapper, and must have two placeholders:

```C
    size_t func_size = 0xdeadbeef;                      // Placeholder to be replaced by actual size

    void* func_offset = (void*)0xcafebabecafebabe;      // (Optional) Placeholder to be replaced by actual function offset
```
- Actually, the _func_offset_ is not always needed: it works to just use `void* func_addr = (void*)&junkle_encrypt;` in Release mode and does not work in Debug mode; as such, according to the compiler/OS pair, it must be tested whether it's possible to directly use a pointer to the target function or if it is needed to perform patching of the function offset (that then require obtaining the process base address).
- The encryption of the functions and the modification of the placeholders are done using a Python script (see the file "requirements.txt" for the dependencies). The script takes 5 parameters: path of the executable to process, path of the map file, output path for the modified executable (can be the same of the first to modify in-place), path of the file containing names of the target _junkle_ / _s_operation_ pairs (names must match those in the map file, names in the pair are space-separated, there is a pair for each line and the last line must terminate with a newline as well), patch of the file containing the license key (one single line terminated by a newline). The script is called in the post-build event (Visual Studio), with the following command-line:

```
python encrypt_and_patch.py $(OutDir)anti_reversing_template.exe $(OutDir)anti_reversing_template.map $(OutDir)anti_reversing_template.exe $(SolutionDir)$(ProjectName)\target_pairs.txt $(SolutionDir)$(ProjectName)\license.txt
```
- There is a mock for obtaining the key in C, this must be replaced by a proper way to obtain the key (e.g., through a tamper-proof device); there is a corresponding mock in the Python script, too, as a design hint to not keep it hardcoded. The encryption algorithm used is AES256 and it skips the last partial block, to keep code size unchanged. The OpenSSL C code that's being used is using some APIs that are deprecated since OpenSSL 3.0, but it was chosen to use that because it's less abstract and does not use heap allocations.
- There is also the implementation of both API-based and time-based anti-debug, that is cross-platform, with an inline function that is included in the encrypted function.
- The `main` tests this process by performing encryption/decryption of some data with an hardcoded key, and printing hex of plaintext, ciphertext and decrypted plaintext. It needs the license key as positional parameter.

## Building with CMake from command-line

Usual flow:

- `cmake -B build -G "Ninja"` (on Linux, you can omit the `-G "Ninja"` option)
- `cmake --build build`

If you installed Clang through Visual Studio, you may have LLvm installed in a folder like `"C:\Program Files\Microsoft Visual Studio\2022\Enterprise\VC\Tools\Llvm"`, but files here are configured such to look for `"C:\Program Files\LLVM"`; you can create a symbolic link and solve the problem without changing all Cmake files. The symbolic link type must be "directory junction", create it like:

```
mklink /J "C:\Program Files\LLVM" "C:\Program Files\Microsoft Visual Studio\2022\Enterprise\VC\Tools\Llvm"
```

- TODO: test with IntelOne
- TODO: test compiling as library
