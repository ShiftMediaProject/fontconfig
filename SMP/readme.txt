
This is a small list of steps in order to build libfontconfig into a msvc dll and/or lib file.

The project contains Release and Debug builds for static lib files (Debug/Release)
  as well as dynamic shared dll files (DebugDLL/ReleaseDLL). Along with the standard
  windows dll/lib configurations mentioned above there are also equivalent variants that
  can be used to compile for WinRT/UWP (These configurations have a WinRT suffix).
There are also architecture configurations for either 32bit (x86) or 64bit (x64) compilation.
Choose whichever project configuration meets your requirements.

The project configurations support being built with various different windows SDK versions.
  By default they will use the lowest SDK version that would be available for Visual Studio
  version 2013 and up (This is the 8.1 SDK). However a batch file is also included 
  (libfontconfig_with_latest_sdk.bat) which can be used to auto detect the newest available SDK 
  installed on the host machine and then open the project using that as the compilation SDK.
  
When using the WinRT/UWP project configurations the projects will automatically compile towards
  the default application target for the Version of Visual Studio being used:
  VS 2013: 8.1
  VS 2015: 8.1
  VS 2017: 10.0.10240.0


*** Generating header files ***

The build system requires the fc-blanks, fc-case, fc-lang headers to be generated. This should have already been done and the resulting
source files being found in the corresponding SMP directories. If these files are missing then the project will try and automatically
generate new ones. If a file needs to be forced to update then it can be simply deleted which will result in new file
being generated the next time the project is built.

For all required headers except fc-blanks a Visual Studio project is provided to build and executable that can be used to create the required headers.
This is done as a build event so simply building the projects will also generate the header file.

In order for a fc-blanks header to be generated python needs to be installed in a location accessible by Visual Studio. An additional extension python-lxml 
is also required to be correctly installed. If fc-blanks header is not found the project will automatically try and use python to generate the required file.

