
This is a small list of steps in order to build libfontconfig into a msvc DLL and lib file.

The project contains Release and Debug builds for static lib files (Debug/Release)
  as well as dynamic shared dll files (DebugDLL/ReleaseDLL).
Choose whichever project configuration meets your requirements.


*** Generating header files ***

The build system requires the fc-blanks, fc-case, fc-glyphname, fc-lang headers to be generated. This should have already been done and the resulting
source files being found in the corresponding SMP directories. If these files are missing then the project will try and automatically
generate new ones. If a file needs to be forced to update then it can be simply deleted which will result in new file
being generated the next time the project is built.

For all required headers except fc-blanks a Visual Studio project is provided to build and executable that can be used to create the required headers.
This is done as a build event so simply building the projects will also generate the header file.

In order for a fc-blanks header to be generated python needs to be installed in a location accessible by Visual Studio. An additional extension python-lxml 
is also required to be correctly installed. If fc-blanks header is not found the project will automatically try and use python to generate the required file.