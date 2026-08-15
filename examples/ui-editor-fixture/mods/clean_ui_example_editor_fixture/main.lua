local function loadContract(mod)
  local source, readError = mod:read("contract.lua")
  assert(source, readError or "unable to read contract.lua")
  local compile = loadstring or load
  local chunk, compileError = compile(source, "@" .. mod.id .. "/contract.lua")
  assert(chunk, compileError)
  local factory = chunk()
  assert(type(factory) == "function", "contract.lua must return a factory")
  local contract = factory(mod)
  assert(type(contract) == "table", "contract factory must return a table")
  return contract
end

local function findHost(mod)
  for _, productId in ipairs({ "gen1_clean_ui", "gen2_clean_ui" }) do
    local dependency = mod:find(productId)
    local host = dependency and dependency.exports
      and dependency.exports.cleanUiHost
    if type(host) == "table" and host.apiVersion == 3 then
      return host
    end
  end
end

return function(mod)
  local contract = loadContract(mod)
  local activeHost
  mod.exports.cleanUiContract = contract

  local function register()
    local host = findHost(mod)
    if activeHost and activeHost ~= host then
      pcall(activeHost.unregister, mod.id, contract.id)
      activeHost = nil
    end
    if not host then return end
    local ok, code, message = host.register(mod.id, contract)
    if ok then
      activeHost = host
    else
      mod.log:warn("Clean UI editor fixture registration failed (%s): %s",
        tostring(code), tostring(message))
    end
  end

  register()
  mod.events:on("mods.loaded", register)
end
