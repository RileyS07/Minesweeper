-- Variables
local coreModule = {}
coreModule.DegbuggingEnabled = false

-- Initialize
function coreModule.Initialize()
    coreModule.Debug("[Core]: Loading "..script.Parent.Name..".")

    -- Loading Modules.
    coreModule.LoadModule("Modules.CoreGuiSetup")
    coreModule.LoadModule("Modules.StateManager")

    coreModule.Debug("[Core]: Done loading "..script.Parent.Name..".")
end


-- Methods
function coreModule.GetObject(objectPath: string, environmentOffset: number?, showDebugMessage: boolean?) : Instance

    -- Initial values for the search.
    local searchLocation: Instance = script
    local searchPathArray: {string}? = string.split(objectPath, ".")

    -- //Path... starts looking from the machine source folder.
    -- /Path... starts looking from the local source script.
    if string.match(objectPath, "^//") then
        searchLocation = script.Parent

        if string.match(objectPath, "^//(.+)") then
            searchPathArray = string.split(string.match(objectPath, "^//(.+)") :: string, ".")
        else
            searchPathArray = nil
        end
    elseif string.match(objectPath, "^/") then
        searchLocation = getfenv(2 + (environmentOffset or 0)).script

        if string.match(objectPath, "^/(.+)") then
            searchPathArray = string.split(string.match(objectPath, "^/(.+)") :: string, ".")
        else
            searchPathArray = nil
        end
    end

    -- Now we follow the searchPathArray and hopefully find the object.
    if searchPathArray then
        for _, childName in next, searchPathArray do
            searchLocation = searchLocation:FindFirstChild(childName)
        end
    end

    -- Do we debug?
    if showDebugMessage then
        coreModule.Debug("[Core]: Fetched "..searchLocation:GetFullName()..".")
    end

    --
    return searchLocation
end


function coreModule.LoadModule(objectPath: string, ...: any)
    local moduleScript = coreModule.GetObject(objectPath, 1)

    if objectPath == "/" then
        for _, child in next, moduleScript:GetChildren() do
            if child:IsA("ModuleScript") then
                coreModule.Debug("[Core]: Loading "..child:GetFullName()..".")
                require(child).Initialize(...)
                coreModule.Debug("[Core]: Loaded "..child:GetFullName()..".")
            end
        end
    else
        coreModule.Debug("[Core]: Loading "..moduleScript:GetFullName()..".")
        require(moduleScript).Initialize(...)
        coreModule.Debug("[Core]: Loaded "..moduleScript:GetFullName()..".")
    end
end


function coreModule.Debug(debugMessage: string, debugFunction: (...any) -> (nil)?)
    if not coreModule.DegbuggingEnabled then return end
    (debugFunction or print)(debugMessage)
end

--
return coreModule