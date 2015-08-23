--
-- Name:        winrt/_preload.lua
-- Purpose:     Define the WinRT APIs
-- Author:      Samuel Surtees
-- Copyright:   (c) 2015 Samuel Surtees and the Premake project
--

	local p = premake
	local api = p.api

--
-- Register the WinRT extension
--

	p.WINSTORE80 = "windowsstore8.0"
	p.WINSTORE81 = "windowsstore8.1"
	p.WINPHONE80 = "windowsphone8.0"
	p.WINPHONE81 = "windowsphone8.1"
	p.WINUNIVERSAL = "windowsuniversal"
	p.ARM = "arm"

	api.addAllowed("system", { p.WINSTORE80, p.WINSTORE81, p.WINPHONE80, p.WINPHONE81, p.WINUNIVERSAL })
	api.addAllowed("architecture", { p.ARM })

--
-- Register the AppxManifest action
--

	newaction {
		trigger = "appxmanifest",
		shortname = "Package.appxmanifest",
		description = "Generate Package.appxmanifest files",

		valid_kinds = { "WindowedApp" },

		onProject = function(prj)
			p.modules.winrt.generateAppxManifest(prj)
		end,

		onCleanProject = function(prj)
			p.clean.directory(prj, prj.name)
		end,
	}

--
-- Register WinRT properties
--

	api.register {
		name = "defaultlanguage",
		scope = "project",
		kind = "string",
	}

	api.register {
		name = "consumewinrtextension",
		scope = "config",
		kind = "string",
		allowed = {
			"true",
			"false",
		},
	}

	api.register {
		name = "deploy",
		scope = "config",
		kind = "string",
		allowed = {
			"true",
			"false",
		},
	}

--
-- Set global environment for the default WinRT platforms
--

	filter { "system:windowsstore8.0 or windowsstore8.1 or windowsphone8.0 or windowsphone8.1 or windowsuniversal", "kind:ConsoleApp or WindowedApp" }
		targetextension ".exe"

	filter { "system:windowsstore8.0 or windowsstore8.1 or windowsphone8.0 or windowsphone8.1 or windowsuniversal", "kind:SharedLib" }
		targetprefix ""
		targetextension ".dll"
		implibextension ".lib"

	filter { "system:windowsstore8.0 or windowsstore8.1 or windowsphone8.0 or windowsphone8.1 or windowsuniversal", "kind:StaticLib" }
		targetprefix ""
		targetextension ".lib"

	filter { "system:windowsphone8.0" }
		toolset "v110_wp80"

	filter { "system:windowsphone8.1" }
		toolset "v120_wp81"

	filter {}

--
-- Decide when the full module should be loaded.
--

	return function(cfg)
		return _ACTION == "appxmanifest" or cfg.system == p.WINSTORE80 or cfg.system == p.WINSTORE81 or cfg.system == p.WINPHONE80 or cfg.system == p.WINPHONE81 or cfg.system == p.WINUNIVERSAL
	end