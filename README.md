# mediaindexer

Automatically creates beautiful filmstrip and waveform images, json/xml metadata and EBU R128 loudness measurements on media files in a watched folder for browsing applications.

### Required executables:
- ffmpeg.exe from https://ffmpeg.zeranoe.com/builds/
- ffprobe.exe from https://ffmpeg.zeranoe.com/builds/
- mxf2raw.exe from https://sourceforge.net/projects/bmxlib/files/
- bmxtranswrap.exe from https://sourceforge.net/projects/bmxlib/files/

### How to use:
- Install [AutoIt](https://www.autoitscript.com/site/autoit/downloads/) 
- Copy required executables into script folder
- Compile Script with [Aut2exe](https://www.autoitscript.com/autoit3/docs/intro/compiler.htm) 
- Define Properties in config.ini
- Run with start.bat

### Properties:
- **Source-Dir**: Directory, you want to watch with media files in it
- **Destination-Dir**: This is where the metadata (json, xml, filmstrips, etc.) will end up
- **DisableRemoval**: mediaindexer will check, if a media file is still present and delete the matching metadata when a file is deleted. Setting this to `1` will suppress this behaviour.