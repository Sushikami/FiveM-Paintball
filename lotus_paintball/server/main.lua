local matchStarted = false
local teams = { }
for i,t in pairs(Config.Paintball.Teams) do
  teams[t.Name] = t
  teams[t.Name].Name = t.Name
  teams[t.Name].Players = { }
end

RegisterServerEvent('lotus_paintball:updatePing')
AddEventHandler('lotus_paintball:updatePing', function()
  if teams ~= { } then
    -- Ensure that this won't throw an error if ping is requested just after a match has ended.
    teams[GetPlayerTeam(source)].Players[source].Ping = GetPlayerPing(source)
    TriggerClientEvent('lotus_paintball:pingResponse', source, teams)
  end
end)

RegisterServerEvent('lotus_paintball:joinTeam')
AddEventHandler('lotus_paintball:joinTeam', function(teamName)
  if not matchStarted then
    if teams[teamName].Players[source] == nil then
      teams[teamName].Players[source] = { Id = source, Name = GetPlayerName(source), Ready = false, Alive = true, Score = 0, Ping = 0 }
      BroadcastEvent("lotus_paintball:joinSuccess", { id = source, team = teamName, dT = teams })
    end
  end
  TriggerClientEvent("lotus_paintball:updateLiveData", -1, teams)
end)

RegisterServerEvent('lotus_paintball:playerReady')
AddEventHandler('lotus_paintball:playerReady', function(teamName)
  if teams[teamName].Players[source].Ready ~= true then
    teams[teamName].Players[source].Ready = true
    if AllPlayersAreReady() and AllTeamsHaveMembers() then
      matchStarted = true
      BroadcastEvent("lotus_paintball:matchStarted", teams)
    else
      BroadcastEvent("lotus_paintball:readySuccess", { id = source, team = teamName, dT = teams })
    end
  end
end)

RegisterServerEvent('esx:onPlayerDeath')
AddEventHandler('esx:onPlayerDeath', function(data)
  data.victim = source

  if data.killedByPlayer then
    local teamOfKiller = GetPlayerTeam(data.killerServerId)
    local teamOfKilled = GetPlayerTeam(data.victim)
    if teamOfKiller ~= teamOfKilled then
      teams[teamOfKiller].Players[data.killerServerId].Score = teams[teamOfKiller].Players[data.killerServerId].Score + 1
    end

    BroadcastEvent("lotus_paintball:killFeed", { killer = GetPlayerName(data.killerServerId), killed = GetPlayerName(data.victim), dT = teams })
  else
    BroadcastEvent("lotus_paintball:killFeed", { killer = nil, killed = GetPlayerName(data.victim), dT = teams })
  end

  if TeamReachedGoal() then
    EndCurrentMatch("[System]") -- Initiate end match sequence
  elseif IsJoinedPlayer(data.victim) and matchStarted then
    -- Automatically respawn player to base if match has started.
    TriggerClientEvent('lotus_paintball:respawnToBase', source, Config.Paintball.RespawnTime * 1000)
  end
end)

RegisterServerEvent('lotus_paintball:endMatch')
AddEventHandler('lotus_paintball:endMatch', function()
  EndCurrentMatch(GetPlayerName(source))
end)

-- Broadcast end event then clear match data.
function EndCurrentMatch(ender)
  local teamMatchData = { }
  for _,t in pairs(teams) do
    local teamScore = 0
    local teamPlayers = ""
    for _,p in pairs(t.Players) do
      teamScore = teamScore + p.Score
      teamPlayers = teamPlayers.." - "..p.Name.." ["..p.Score.."]\n"
    end

    if teamPlayers ~= "" then -- For some reason Discord Webhook doesn't take empty fields.
      table.insert(teamMatchData, { name = "Team "..t.Name.." : ["..teamScore.."]", value = teamPlayers, inline = true })
    end
  end

  PerformHttpRequest(Config.Discord.WebhookURL, function(err, text, headers) end, 'POST', json.encode({
    avatar_url = Config.Discord.AvatarURL,
    username = Config.Discord.Username,
    embeds = {{
      color = 2003199,
      title = "Paintball Match Results",
      fields = teamMatchData,
      footer = { text = "Match ended by: "..ender.." at "..os.date("%x %X") },
    }}
  }), { ['Content-Type'] = 'application/json' })

  BroadcastEvent("lotus_paintball:matchEnded", ender)
  TriggerClientEvent("lotus_paintball:updateLiveData", -1, { })

  matchStarted = false
  teams = { }
  for i,t in pairs(Config.Paintball.Teams) do
    teams[t.Name] = t
    teams[t.Name].Name = t.Name
    teams[t.Name].Players = { }
  end
end

-- Check if team score is reached.
function TeamReachedGoal()
  local isGoalReached = false
  for _,t in pairs(teams) do
    local teamScore = 0
    for _,p in pairs(t.Players) do
      teamScore = teamScore + p.Score
    end

    if teamScore >= Config.Paintball.ScoreGoal then isGoalReached = true end
  end

  return isGoalReached
end

-- Trigger event to joined players
function BroadcastEvent(eventName, payload)
  for _,t in pairs(teams) do
    for _,p in pairs(t.Players) do
      TriggerClientEvent(eventName, p.Id, payload)
    end
  end
end

-- Check if all joined players are ready.
function AllPlayersAreReady()
  local allPlayersReady = true
  for _,t in pairs(teams) do
    for _,p in pairs(t.Players) do
      if not p.Ready then allPlayersReady = false end
    end
  end

  return allPlayersReady
end

-- Get the team name of the player
function GetPlayerTeam(Id)
  local nameOfTeam
  for _,t in pairs(teams) do
    for _,p in pairs(t.Players) do
      if p.Id == Id then nameOfTeam = t.Name end
    end
  end

  return nameOfTeam
end

-- Check if Player is part of Paintball match
function IsJoinedPlayer(Id)
  local joinedPlayer = false
  for _,t in pairs(teams) do
    for _,p in pairs(t.Players) do
      if p.Id == Id then joinedPlayer = true end
    end
  end

  return joinedPlayer
end

-- Check if all teams have members regardless of split.
function AllTeamsHaveMembers()
  local teamsHaveMembers = true
  for _,t in pairs(teams) do
    local numberOfMembers = 0
    for _,p in pairs(t.Players) do
      numberOfMembers = numberOfMembers + 1
    end

    if numberOfMembers == 0 then teamsHaveMembers = false end
  end

  return teamsHaveMembers
end
