# Premake Extension to support Windows Runtime projects

## Usage

This module extends the Visual Studio actions (`premake5 vs2013`)

Dictating the target device: (required)

`system "windowsphone8.1"`

Allowed values are "windowsstore8.0", "windowsstore8.1", "windowsphone8.0", "windowsphone8.1" and "windowsuniversal", supported systems is listed below in Notes.

ARM has been added to the list of supported platforms: (required if you're aiming for ARM devices)

`platforms { "ARM" }`

If you need to set the "Consume Windows Runtime Extension" property you can do so using (not required)

`consumewinrtextension "false"`

This property can be applied to individual files using: (not required)
```
filter { "files:WinRT_File.cpp" }
	consumewinrtextension "true"
```

If you need to deploy files (such as all the images listed in your Package.appxmanifest file, or a DLL that is **built for WinRT**): (required for assets)
```
filter { "files:Assets/*.png" }
	deploy "true"
```

If you need to disable the generation of the Windows Metadata file:
`generatewinmd "false"`

I believe you need to dictate a "default language", this can be done using: (required?)

`defaultlanguage "en-AU"`

**Finally**, you will need the Package.appxmanifest file mentioned earlier. Unfortunately, this file can't be made using Visual Studio (atleast I couldn't find it), and it requires a number of things to be done to work properly.

If you run `premake5 appxmanifest` it will generate a base manifest for you to use, firstly you'll need to open it in a text editor and edit the following entries:
* `Publisher`, you will need the "CN=" first, not sure why
* `PublisherDisplayName`
* `Executable` and `EntryPoint`, I believe this are the same value with different extensions. Ours are just the project name and that works fine (our output file is the project name too)

The rest of the values can either be edited here or in the built-in editor in Visual Studio. I recommend using the editor, as there's other kinds of images that can be added to the manifest.

You will need the following images to build and deploy:
* Logo (StoreLogo.png)
* Splash Screen (SplashScreen.png)
* Square 150x150 Logo
* Square 30x30 Logo, or Square 44x44 Logo, depending on the type of project

If I have forgotten anything or if there is any issues, please open an issue (or pull request) and I'll try to get it sorted out.

## Notes

### Supported projects:
* Windows Phone 8.1 x86 and ARM
* Windows Store 8.1 x86, x86_64 and ARM

### TODO:
* Universal Store Apps (Partial support)
* Windows Phone 8.1 (Requires manifest equiv.)
