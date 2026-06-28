local minutesLeft = 0
local mailList = {}
local hasMailList = false

local remoteUpdates = {}

local function countRemoteUpdates()
  local updCount = 0
  for _, mailUpdates in pairs(remoteUpdates) do
    updCount = updCount + mailUpdates
  end
  noctalia.state.set("remoteUpdates", updCount)
end

local function parseRemoteUpdates(body)
  local packageList = {}; local packageCount = 0
  for line in body:gmatch("([^\n]*)\n?") do
    packageName = line:gmatch("%w+")()
    if packageName ~= nil then
      if packageList[packageName] == nil then
        packageCount = packageCount +1
      end
      packageList[packageName] = true
    end
  end
  return packageCount
end

local function checkRemoteUpdatesByMail(mail)
  local updateFile = "https://repo-default.voidlinux.org/void-updates/void-updates".. "/updates_" .. mail .. ".txt"
  noctalia.http({ url = updateFile }, function(result)
    if result.ok then
      remoteUpdates[mail] = parseRemoteUpdates(result.body)
      countRemoteUpdates()
      -- noctalia.log(`void-packages: mail {mail} has {remoteUpdates[mail]} updates`)
    end
  end)
end

local function checkRemoteUpdates()
  local checkRemote = noctalia.getConfig("remote_updates")
  if hasMailList == true and checkRemote == true then
    noctalia.log(`void-packages: running remote check`)
    for _, mail in pairs(mailList) do
      checkRemoteUpdatesByMail(mail)
    end
  end
end

local function checkLocalUpdates()
  noctalia.log(`void-packages: running local check`)
  noctalia.runAsync("xbps-install -Mun | awk '{print $1}' | xargs xbps-uhelper getpkgname", function(result)
    if result.exitCode == 0 then
      local updCount = 0
      for pkgName in result.stdout:gmatch("([^\n]*)\n?") do
        if pkgName ~= nil and pkgName ~= "" then
          updCount = updCount +1
          -- noctalia.log(`void-packages: local package {pkgName} has updates`)
        end
      end
      noctalia.state.set("localUpdates", updCount)
    end
  end)
end

local function runUpdate()
  checkLocalUpdates()
  checkRemoteUpdates()
end

local function initMailList()
  mailList = noctalia.getConfig("maintainer_mail")
  if #mailList == 0 then
    noctalia.runAsync("git config get user.email", function(result)
      if result.exitCode == 0 then
        if result.stdout ~= "" then
          mailList[0] = result.stdout
          noctalia.log(`void-packages: used git user.email {mailList[0]}`)
          hasMailList = true
          checkRemoteUpdates()
        else
          noctalia.log(`void-packages: git user.email empty!`)
        end
      end
    end)
  else
    hasMailList = true
  end
end

function update()
  if minutesLeft <= 0 then
    runUpdate()
    minutesLeft = 1440 / noctalia.getConfig("checks_per_day")
    noctalia.log(`void-packages: next update in {minutesLeft} minutes`)
  else
    minutesLeft = minutesLeft -1
  end
end

initMailList()
noctalia.setUpdateInterval(60000)
--noctalia.state.set("localUpdates", localUpdates)
--noctalia.state.set("remoteUpdates", remoteUpdates)
