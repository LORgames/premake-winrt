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

	p.override(p.vstudio.vc2010, "emitFiles", function(base, prj, group, tag, fileFunc, fileCfgFunc, checkFunc)
		if isWinRT(prj.system) then
			if tag == "ClCompile" then
				fileCfgFunc = table.join(fileCfgFunc or {}, {
					m.compileAsWinRT,
				})
			elseif tag == "None" then
				fileCfgFunc = table.join(fileCfgFunc or {}, {
					m.deploymentContent,
				})
			end
		end

		base(prj, group, tag, fileFunc, fileCfgFunc, checkFunc)
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

	p.vstudio.vc2010.categories.AppxManifest = {
		name = "AppxManifest",
		extensions = { ".appxmanifest" },
		priority = 99,

		emitFiles = function(prj, group)
			p.vstudio.vc2010.emitFiles(prj, group, "AppxManifest", { p.vstudio.vc2010.generatedFile })
		end,

		emitFilter = function(prj, group)
			p.vstudio.vc2010.filterGroup(prj, group, "AppxManifest")
		end
	}

	p.override(p.vstudio.vc2010.elements, "link", function(base, cfg, explicit)
		local elements = base(cfg, explicit)
		elements = table.join(elements, {
			m.generateWINMD,
		})
		return elements
	end)


	premake.override(p.vstudio.sln2005.elements, "projectConfigurationPlatforms", function(oldfn, cfg, context)
		local elements = oldfn(cfg, context)

		elements = table.join(elements, {
			m.deployProject
		})

		return elements
	end)


	function m.deployProject(cfg, context)
		if isWinRT(context.prj.system) and context.prj.kind == p.WINDOWEDAPP then
			p.w('{%s}.%s.Deploy.0 = %s|%s', context.prj.uuid, context.descriptor, context.platform, context.architecture)
		end
	end

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

	function m.deploymentContent(fcfg, condition)
		if fcfg and fcfg.deploy then
			p.vstudio.vc2010.element("DeploymentContent", nil, fcfg.deploy)
		end
	end

	function m.windowsAppContainer(cfg)
		if isWinRT(cfg.system) then
			p.vstudio.vc2010.element("WindowsAppContainer", nil, "true")
		end
	end

	function m.generateWINMD(cfg, explicit)
		if cfg.generatewinmd then
			p.vstudio.vc2010.element("GenerateWindowsMetadata", nil, cfg.generatewinmd)
		end
	end

	include("winrt_appxmanifest.lua")

	return m
