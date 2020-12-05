VERSION = "0.1"

local micro = import("micro")
local shell = import("micro/shell")
local buffer = import("micro/buffer")
local config = import("micro/config")
local util = import("micro/util")
local utf = import("unicode/utf8")

function startswith(str, start)
   return string.sub(str,1,string.len(start))==start
end

function endswith(str, endStr)
   return endStr=='' or string.sub(str,-string.len(endStr))==endStr
end

-- config.SetGlobalOptionNative("*.lichen",{filetype = "lua"})

function init()
    config.MakeCommand("launchLichen", launchLichen, config.NoComplete)
    config.MakeCommand("evaluateBlock", evaluateBlock, config.NoComplete)
    config.AddRuntimeFile("lichen", config.RTHelp, "help/lichen.md")
    config.TryBindKey("Alt->", "command:evaluateBlock", true)
end

function isLichenFile(buf)
	return endswith(buf.Path, ".lichen")
end


function onLichenOut(output)
	buffer.Log("lichen: "..output)
end
function onLichenErr(err)
	buffer.Log("lichen: error -"..err)
end
function onLichenExit(str, stuff)
	buffer.Log("lichen: "..str)
	closeLichen()
end

job = nil

function runLichen(buf, onExit, ...)
	buffer.Log("lichen: launching lichen!")

    local options = {"--backend", "pulseaudio"}

    job = shell.JobSpawn("lichen", options, onLichenOut,
            onLichenErr, onLichenExit, {})

    -- job.Stdin:Close()

end


function launchLichen(bp, args)

	local buf = bp.Buf
	buffer.Log("will attempt to launch lichen...")
    if(isLichenFile(buf)) then
        evaluateBlock(bp, args)
        buffer.Log("lichen: launched and file sent to evaluate...")
    end
end

function evaluateBlock(bp,args)
	buffer.Log("lichen: launching lichen!")
	local buf = bp.Buf

    if(isLichenFile(buf)) then
        if(job==nil) then
            runLichen(bp.Buf)
        end

        if(job ~=  nil) then
        	shell.JobSend(job, "l".. buf.AbsPath .."\n")
        	-- job.Stdin:Close()
        end
        
    end

end

function closeLichen()
	if(job ~= nil) then
		shell.JobSend(job, "q")
	    job.Stdin:Close()
	    job = nil
	end
end

function quit(buf)
    closeLichen()
end

function onBufferOpen(buf)
    if not endswith(buf.Path, ".lichen") then
        return
    end

    buffer.Log("lichen: opening lichen file...")

    buf:UpdateRules()
end
