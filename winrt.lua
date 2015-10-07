--
-- Create a WinRT namespace to isolate the additions
--

	local p = premake

	p.modules.winrt = {}

	local m = p.modules.winrt
	m._VERSION = "0.0.1"

--
-- Local functions
--

	local function isWinRT(_system)
		local system = _system or ""
		system = system:lower()
		return system == p.WINSTORE80 or system == p.WINSTORE81 or system == p.WINPHONE80 or system == p.WINPHONE81 or system == p.WINUNIVERSAL
	end

--
-- Override vs2010 project creation functions
--

	if p.vstudio.vs2010_architectures ~= nil then
		p.vstudio.vs2010_architectures.arm = "ARM"
	end

	p.override(p.vstudio.vc2010.elements, "globals", function(base, prj)
		local elements = base(prj)
		if isWinRT(prj.system) then
			elements = table.join(elements, {
				m.defaultLanguage,
				m.applicationType,
			})
		end
		return elements
	end)

	p.override(p.vstudio.vc2010.elements, "configurationProperties", function(base, cfg)
		local elements = base(cfg)
		if cfg.kind ~= p.UTILITY then
			elements = table.join(elements, {
				m.windowsAppContainer,
			})
		end
		return elements
	end)

	p.override(p.vstudio.vc2010.elements, "ClCompileFileCfg", function(base, fcfg, condition)
		local elements = base(fcfg, condition)
		elements = table.join(elements, {
			m.compileAsWinRT,
		})
		return elements
	end)

	p.override(p.vstudio.vc2010, "characterSet", function(base, cfg)
		if not isWinRT(cfg.system) then
			base(cfg)
		end
	end)

	p.override(p.vstudio.vc2010, "compileAs", function(base, cfg)
		base(cfg)

		if cfg.consumewinrtextension ~= nil then
			p.vstudio.vc2010.element("CompileAsWinRT", nil, cfg.consumewinrtextension)
		end
	end)

	p.override(p.vstudio.vc2010, "entryPointSymbol", function(base, cfg)
		if cfg.entrypoint or not isWinRT(cfg.system) then
			base(cfg)
		end
	end)

	p.override(p.vstudio.vc2010, "keyword", function(base, prj)
		local _isWinRT
		for cfg in p.project.eachconfig(prj) do
			if isWinRT(cfg.system) then
				_isWinRT = true
			end
		end

		if _isWinRT then
			p.vstudio.vc2010.element("AppContainerApplication", nil, "true")
		else
			base(prj)
		end
	end)

	p.override(p.vstudio.vc2010, "debuggerFlavor", function(base, cfg)
		if not isWinRT(cfg.system) then
			base(cfg)
		end
	end)

	p.override(p.vstudio.vc2010, "categorizeFile", function(base, prj, file)
		if m.isAppxmanifest(file.name) then
			return "AppxManifest"
		end

		return base(prj, file)
	end)

	p.override(p.vstudio.vc2010.elements, "files", function(base, prj, groups)
		local elements = base(prj, groups)
		elements = table.join(elements, {
			m.appxmanifestFiles,
		})
		return elements
	end)

	p.override(p.vstudio.vc2010.elements, "link", function(base, cfg, explicit)
		local elements = base(cfg, explicit)
		elements = table.join(elements, {
			m.generateWINMD,
		})
		return elements
	end)

	-- Due to the vstudio section in premake not being 100% module friendly, this override is messed up
	p.override(p.vstudio.sln2005, "sections", function(base, wks)
		p.vstudio.sln2005.sectionmap.ConfigurationPlatforms = function(wks)
			local vstudio = p.vstudio
			local sln2005 = p.vstudio.sln2005
			local project = p.project
			local tree = p.tree

			local descriptors = {}
			local sorted = {}

			for cfg in p.workspace.eachconfig(wks) do

				-- Create a Visual Studio solution descriptor (i.e. Debug|Win32) for
				-- this solution configuration. I need to use it in a few different places
				-- below so it makes sense to precompute it up front.

				local platform = vstudio.solutionPlatform(cfg)
				descriptors[cfg] = string.format("%s|%s", cfg.buildcfg, platform)

				-- Also add the configuration to an indexed table which I can sort below

				table.insert(sorted, cfg)

			end

			-- Sort the solution configurations to match Visual Studio's preferred
			-- order, which appears to be a simple alpha sort on the descriptors.

			table.sort(sorted, function(cfg0, cfg1)
				return descriptors[cfg0]:lower() < descriptors[cfg1]:lower()
			end)

			-- Now I can output the sorted list of solution configuration descriptors

			-- Visual Studio assumes the first configurations as the defaults.
			if wks.defaultplatform then
				_p(1,'GlobalSection(SolutionConfigurationPlatforms) = preSolution')
				table.foreachi(sorted, function (cfg)
					if cfg.platform == wks.defaultplatform then
						_p(2,'%s = %s', descriptors[cfg], descriptors[cfg])
					end
				end)
				_p(1,"EndGlobalSection")
			end

			_p(1,'GlobalSection(SolutionConfigurationPlatforms) = preSolution')
			table.foreachi(sorted, function (cfg)
				if not wks.defaultplatform or cfg.platform ~= wks.defaultplatform then
					_p(2,'%s = %s', descriptors[cfg], descriptors[cfg])
				end
			end)
			_p(1,"EndGlobalSection")

			-- For each project in the solution...

			_p(1,"GlobalSection(ProjectConfigurationPlatforms) = postSolution")

			local tr = p.workspace.grouptree(wks)
			tree.traverse(tr, {
				onleaf = function(n)
					local prj = n.project

					-- For each (sorted) configuration in the solution...

					table.foreachi(sorted, function (cfg)

						local platform, architecture

						-- Look up the matching project configuration. If none exist, this
						-- configuration has been excluded from the project, and should map
						-- to closest available project configuration instead.

						local prjCfg = project.getconfig(prj, cfg.buildcfg, cfg.platform)
						local excluded = (prjCfg == nil or prjCfg.flags.ExcludeFromBuild)

						if prjCfg == nil then
							prjCfg = project.findClosestMatch(prj, cfg.buildcfg, cfg.platform)
						end

						local descriptor = descriptors[cfg]
						local platform = vstudio.projectPlatform(prjCfg)
						local architecture = vstudio.archFromConfig(prjCfg, true)

						_p(2,'{%s}.%s.ActiveCfg = %s|%s', prj.uuid, descriptor, platform, architecture)

						-- Only output Build.0 entries for buildable configurations

						if not excluded and prjCfg.kind ~= premake.NONE then
							_p(2,'{%s}.%s.Build.0 = %s|%s', prj.uuid, descriptor, platform, architecture)
						end


						---------------------------------------------------------------------------------
						--                            This is the WinRT code!                           -
						---------------------------------------------------------------------------------
						if isWinRT(prjCfg.system) and prjCfg.kind == p.WINDOWEDAPP then
							_p(2,'{%s}.%s.Deploy.0 = %s|%s', prj.uuid, descriptor, platform, architecture)
						end


					end)
				end
			})
			_p(1,"EndGlobalSection")
		end

		base(wks)
	end)

	p.override(p.vstudio.vc2010.elements, "NoneFileCfg", function(base, fcfg, condition)
		local elements = base(fcfg, condition)
		elements = table.join(elements, {
			m.deploymentContent,
		})
		return elements
	end)

	p.override(p.vstudio.vc2010, "userMacros", function(base, cfg)
		if cfg.certificatefile ~= nil or cfg.certificatethumbprint ~= nil then
			p.vstudio.vc2010.propertyGroup(nil, "UserMacros")

			if cfg.certificatefile ~= nil then
				p.vstudio.vc2010.element("PackageCertificateKeyFile", nil, cfg.certificatefile)
			end

			if cfg.certificatethumbprint ~= nil then
				p.vstudio.vc2010.element("PackageCertificateThumbprint", nil, cfg.certificatethumbprint)
			end

			p.pop('</PropertyGroup>')
		else
			base(cfg)
		end
	end)

	function m.applicationType(prj)
		local type
		local revision
		if prj.system == p.WINPHONE80 then
			type = "Windows Phone"
			revision = "8.0"
		elseif prj.system == p.WINPHONE81 then
			type = "Windows Phone"
			revision = "8.1"
		elseif prj.system == p.WINSTORE80 then
			type = "Windows Store"
			revision = "8.0"
		elseif prj.system == p.WINSTORE81 then
			type = "Windows Store"
			revision = "8.1"
		elseif prj.system == p.WINUNIVERSAL then
			type = "Windows Store"
			revision = "8.2"
		end
		p.vstudio.vc2010.element("ApplicationType", nil, type)
		p.vstudio.vc2010.element("ApplicationTypeRevision", nil, revision)
	end

	function m.defaultLanguage(prj)
		if prj.defaultlanguage ~= nil then
			p.vstudio.vc2010.element("DefaultLanguage", nil, prj.defaultLanguage)
		end
	end

	function m.compileAsWinRT(fcfg, condition)
		if fcfg and fcfg.consumewinrtextension then
			p.vstudio.vc2010.element("CompileAsWinRT", condition, fcfg.consumewinrtextension)
		end
	end

	function m.windowsAppContainer(cfg)
		if isWinRT(cfg.system) then
			p.vstudio.vc2010.element("WindowsAppContainer", nil, "true")
		end
	end

	function m.isAppxmanifest(fname)
		return path.hasextension(fname, { ".appxmanifest" })
	end

	function m.appxmanifestFiles(prj, groups)
		p.vstudio.vc2010.emitFiles(prj, groups, "AppxManifest")
	end

	function p.vstudio.vc2010.elements.AppxManifestFile(cfg, file)
		return {}
	end

	function p.vstudio.vc2010.elements.AppxManifestFileCfg(fcfg, condition)
		return {}
	end

	function m.deploymentContent(fcfg, condition)
		if fcfg and fcfg.deploy then
			p.vstudio.vc2010.element("DeploymentContent", nil, fcfg.deploy)
		end
	end

	function m.generateWINMD(cfg, explicit)
		if cfg.generatewinmd then
			p.vstudio.vc2010.element("GenerateWindowsMetadata", nil, cfg.generatewinmd)
		end
	end

	include("winrt_appxmanifest.lua")

	return m
