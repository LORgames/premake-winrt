--
-- Grab the WinRT namespace to isolate the additions
--

	local p = premake
	local m = p.modules.winrt
	local vs2010 = p.vstudio.vs2010

--
-- Create Package.appxmanifest
--

	function m.generateAppxManifest(prj)
		p.eol("\r\n")
		p.indent("  ")
		p.escaper(vs2010.esc)

		p.generate(prj, "Package.appxmanifest", m.generate)
	end

	function m.generate(prj)
		_p('<?xml version="1.0" encoding="utf-8"?>')
		_p('<Package')
		if prj.system == p.WINUNIVERSAL then
			_p('xmlns="http://schemas.microsoft.com/appx/manifest/foundation/windows10"')
		else
			_p('xmlns="http://schemas.microsoft.com/appx/2010/manifest"')
		end

		if prj.system == p.WINPHONE81 then
			_p('xmlns:m2="http://schemas.microsoft.com/appx/2013/manifest"')
		end

		if prj.system == p.WINPHONE81 then
			_p('xmlns:m3="http://schemas.microsoft.com/appx/2014/manifest"')
		elseif prj.system == p.WINSTORE81 then
			_p('xmlns:m3="http://schemas.microsoft.com/appx/2013/manifest"')
		elseif prj.system == p.WINUNIVERSAL then
			_p('xmlns:m3="http://schemas.microsoft.com/appx/manifest/uap/windows10"')
		end

		if prj.system == p.WINUNIVERSAL or prj.system == p.WINPHONE81 then
			_p('xmlns:mp="http://schemas.microsoft.com/appx/2014/phone/manifest"')
		end

		_p('>')

		_p(1,'<Identity Name="%s"', prj.uuid)
		_p(2,'Publisher="CN=PublisherName"')
		_p(2,'Version="0.0.0.0" />')

		if prj.system == p.WINUNIVERSAL or prj.system == p.WINPHONE81 then
			_p(1,'<mp:PhoneIdentity PhoneProductId="%s" PhonePublisherId="00000000-0000-0000-0000-000000000000"/>', prj.uuid)
		end

		_p(1,'<Properties>')
		_p(2,'<DisplayName>%s</DisplayName>', prj.name)
		_p(2,'<PublisherDisplayName>PublisherName</PublisherDisplayName>')
		_p(2,'<Logo>Logo.png</Logo>')
		_p(1,'</Properties>')

		_p(1,'<Prerequisites>')
		if prj.system == p.WINUNIVERSAL then
			_p(1,'<Dependencies>')
			_p(2,'<TargetDeviceFamily Name="Windows.Universal" MinVersion="10.0.10069.0" MaxVersionTested="10.0.10069.0" />')
			_p(1,'</Dependencies>')
		else
			_p(1,'<OSMinVersion>6.3.0</OSMinVersion>')
			_p(1,'<OSMaxVersionTested>6.3.0</OSMaxVersionTested>')
		end
		_p(1,'</Prerequisites>')

		_p(1,'<Resources>')
		_p(2,'<Resource Language="x-generate"/>')
		_p(1,'</Resources>')
		
		_p(1,'<Applications>')
		_p(2,'<Application Id="App"')
		_p(3,'Executable="$targetnametoken$.exe"')
		_p(3,'EntryPoint="$safeprojectname$.App">')
		_p(3,'<m3:VisualElements')
		_p(4,'DisplayName="$projectname$"')
		_p(4,'Description="$projectname$"')
		_p(4,'ForegroundText="light"')
		_p(4,'BackgroundColor="transparent">')
		_p(4,'<m3:SplashScreen Image="SplashScreen.png"/>')
		_p(3,'</m3:VisualElements>')
		_p(2,'</Application>')
		_p(1,'</Applications>')
		
		_p(1,'<Capabilities></Capabilities>')

		_p('</Package>')
	end