ESX = nil
TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
print("Lotus Paintball, client started")

local f = Config.Paintball.Field
local exit = Config.Paintball.Field.Exit
local playerData = { }
local matchData = { }

Citizen.CreateThread(function()
  AddMapBlip(f.x, f.y, f.z, f.Blip, f.Color, f.Name) -- Entrance blip
  for i,t in pairs(Config.Paintball.Teams) do
    AddMapBlip(t.x2, t.y2, t.z2, t.Blip, t.Color, "Team "..t.Name) -- Team blip
  end

  while true do
    local playerPed = PlayerPedId()
    local playerPedCoords = GetEntityCoords(playerPed)
    for _,v in pairs(Config.Paintball.Teams) do
      -- Team base marker
      DrawMarker(v.m2, v.x2, v.y2, v.z2, 0, 0, 0, 0, 0, 0, 2.0, 2.0, 2.0, v.r2, v.g2, v.b2, v.a2, 0, 1, 2, 0, 0, 0, 0)
      if GetDistanceBetweenCoords(playerPedCoords, v.x2, v.y2, v.z2, true) < 1.5 then
        ESX.ShowHelpNotification("Press [E] if you're ready.")
        if IsControlJustReleased(0, 38) then
          TriggerServerEvent("lotus_paintball:playerReady", v.Name)
        end
      end

      -- Entrance marker
      DrawMarker(v.m, v.x, v.y, v.z, 0, 0, 0, 0, 0, 0, 2.0, 2.0, 0.5, v.r, v.g, v.b, v.a, 0, 1, 2, 0, 0, 0, 0)
      local playerDistanceFromEntrance = GetDistanceBetweenCoords(playerPedCoords, v.x, v.y, v.z, true)
      if playerDistanceFromEntrance < 1.5 then
        ESX.ShowHelpNotification("Press [E] to join team ".. v.Name ..".")
        if IsControlJustReleased(0, 38) then
          if playerData.Joined ~= true then
            playerData = { team = v.Name, x = v.x2, y = v.y2, z = v.z2, r = v.r, g = v.g, b = v.b, a = v.a }
            TriggerServerEvent("lotus_paintball:joinTeam", v.Name)
          else
            ESX.ShowNotification("You're already part of a team!")
          end
        end
      elseif playerDistanceFromEntrance < 10.0 then
        local teamBanner = "[ Team "..v.Name.." ]\n"
        if matchData ~= { } then
          if(matchData[v.Name] ~= nil) then
            for _,p in pairs(matchData[v.Name].Players) do
              -- Append the member's names for each team once available.
              teamBanner = teamBanner..p.Name.."\n"
            end
          end
        end
        -- Draw text in mid-air
        DrawText3D(v.x, v.y, v.z + 1.5, teamBanner, v.r, v.g, v.b)
      end
    end

    -- End match marker
    if playerData.Joined == true then
      DrawMarker(exit.m, exit.x, exit.y, exit.z, 0, 0, 0, 0, 0, 0, 6.0, 6.0, 0.5, exit.r, exit.g, exit.b, exit.a, 0, 1, 2, 0, 0, 0, 0)
      if GetDistanceBetweenCoords(playerPedCoords, exit.x, exit.y, exit.z, true) < 3.5 then
        ESX.ShowHelpNotification("Press [E] to end the match.")
        if IsControlJustReleased(0, 38) then
          TriggerServerEvent("lotus_paintball:endMatch")
        end
      end
    end

    Citizen.Wait(0)
  end
end)

RegisterNetEvent('lotus_paintball:joinSuccess')
AddEventHandler('lotus_paintball:joinSuccess', function(player)
  -- conditional latch as this only needs to run once.
  if playerData.Joined ~= true then playerData.Joined = true
    local playerPed = PlayerPedId()
    RespawnPed(playerPed, { x = playerData.x, y = playerData.y, z = playerData.z + 0.5 }, 0.0)

    -- Draw player markers
    Citizen.CreateThread(function()
      while playerData.Joined do
        for _,t in pairs(matchData) do
          for _,p in pairs(t.Players) do
            local pCoords = GetEntityCoords(p.PlayerPedId, true)
            DrawMarker(1, pCoords.x, pCoords.y, pCoords.z-1, 0, 0, 0, 0, 0, 0, 0.6, 0.6, 0.4, t.r, t.g, t.b, t.a, 0, 1, 2, 0, 0, 0, 0)
          end
        end

        Citizen.Wait(5)
      end
    end)

    -- Update player ping every 5 seconds.
    Citizen.CreateThread(function()
      while playerData.Joined do
        TriggerServerEvent("lotus_paintball:updatePing")
        Citizen.Wait(5 * 1000)
      end
    end)

    SendNUIMessage({ action = 'toggleUi', value = true }) -- only togger the UI once!
    ESX.ShowNotification(GetPlayerName(GetPlayerFromServerId(player.id)).." joined Team "..player.team)
  end

  -- update UI for every player that joins.
  SendNUIMessage({ action = 'update', value = player.dT })
end)

RegisterNetEvent('lotus_paintball:pingResponse')
AddEventHandler('lotus_paintball:pingResponse', function(data)
  SendNUIMessage({ action = 'update', value = data })
end)

RegisterNetEvent('lotus_paintball:updateLiveData')
AddEventHandler('lotus_paintball:updateLiveData', function(data)
  matchData = data
end)

RegisterNetEvent('lotus_paintball:readySuccess')
AddEventHandler('lotus_paintball:readySuccess', function(player)
  SendNUIMessage({ action = 'update', value = player.dT })
	ESX.ShowNotification(GetPlayerName(GetPlayerFromServerId(player.id)).." is ready")
end)

RegisterNetEvent('lotus_paintball:matchStarted')
AddEventHandler('lotus_paintball:matchStarted', function(teams)
  matchData = teams
  for _,t in pairs(matchData) do
    for _,p in pairs(t.Players) do
      p.PlayerPedId = GetPlayerPed(GetPlayerFromServerId(p.Id))
    end
  end

  SendNUIMessage({ action = 'update', value = matchData })
	ESX.ShowNotification("All players are ready. Match has started: First team to reach ["..Config.Paintball.ScoreGoal.."] points wins!")
end)

RegisterNetEvent('lotus_paintball:killFeed')
AddEventHandler('lotus_paintball:killFeed', function(killInfo)
	if killInfo.killer ~= nil then
    SendNUIMessage({ action = 'update', value = killInfo.dT })
    ESX.ShowNotification(killInfo.killer.." killed "..killInfo.killed.."!")
  else
    ESX.ShowNotification(killInfo.killed.." died.")
  end
end)

RegisterNetEvent('lotus_paintball:respawnToBase')
AddEventHandler('lotus_paintball:respawnToBase', function(waitTime)
  Citizen.Wait(waitTime)
	TriggerServerEvent('esx_ambulancejob:setDeathStatus', false)

	Citizen.CreateThread(function()
		--DoScreenFadeOut(500)
		--while not IsScreenFadedOut() do Citizen.Wait(50) end

		local formattedCoords = { x = playerData.x, y = playerData.y, z = playerData.z + 0.5 }
		ESX.SetPlayerData('lastPosition', formattedCoords)
		TriggerServerEvent('esx:updateLastPosition', formattedCoords)
		RespawnPed(PlayerPedId(), formattedCoords, 0.0)
		StopScreenEffect('DeathFailOut')

		--DoScreenFadeIn(500)
	end)
end)

RegisterNetEvent('lotus_paintball:matchEnded')
AddEventHandler('lotus_paintball:matchEnded', function(playerName)
  local ped = PlayerPedId()
  playerData = { }
  matchData = { }

  RespawnPed(ped, {x = f.x, y = f.y, z = f.z}, 0.0)
  RemoveWeaponFromPed(ped, GetHashKey("WEAPON_APPISTOL")) -- remove provided paintball gun

  SendNUIMessage({ action = 'toggleUi', value = false })
	ESX.ShowNotification(playerName.." has ended the match.")
end)

-- Add blip on map.
function AddMapBlip(x, y, z, b, c, text)
  local blip = AddBlipForCoord(x, y, z)
    SetBlipSprite(blip, b)
    SetBlipColour(blip, c)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(text)
    SetBlipAsShortRange(blip, true)
    EndTextCommandSetBlipName(blip)
end

-- Respawn ped reset armor to full, and give weapon kit.
function RespawnPed(ped, coords, heading)
  TriggerEvent('playerSpawned')
  Citizen.Wait(5) -- Give time for event to run
  SetEntityCoordsNoOffset(ped, coords.x, coords.y, coords.z, false, false, false, true)
	NetworkResurrectLocalPlayer(coords.x, coords.y, coords.z, heading, true, false)
	SetPlayerInvincible(ped, false)
	ClearPedBloodDamage(ped)
  SetPedArmour(ped, 100) -- free armor! :P
  GivePaintballKit(ped) -- free gun! :P
	ESX.UI.Menu.CloseAll()
end

-- Give the player the approved paintball gun
function GivePaintballKit(ped)
  local weaponHash = GetHashKey("WEAPON_APPISTOL")
  -- RemoveAllPedWeapons(ped, true) -- this is to ensure only the approved paintball gun is used.
  GiveWeaponToPed(ped, weaponHash, 250, false, true) -- provide approved paintball weapon
  GiveWeaponComponentToPed(ped, weaponHash, GetHashKey("COMPONENT_AT_PI_SUPP")) -- adds realism as paintball guns are quiet
  GiveWeaponComponentToPed(ped, weaponHash, GetHashKey("COMPONENT_AT_PI_FLSH")) -- adds realism as paintball guns are quiet
  GiveWeaponComponentToPed(ped, weaponHash, GetHashKey("COMPONENT_APPISTOL_CLIP_02")) -- additional mag cap!
end

function DrawText3D(x, y, z, text, r, g, b)
    local onScreen,_x,_y=World3dToScreen2d(x,y,z)
    local px,py,pz=table.unpack(GetGameplayCamCoords())
    local dist = GetDistanceBetweenCoords(px,py,pz, x,y,z, 1)

    local scale = (1/dist)*2
    local fov = (1/GetGameplayCamFov())*100
    local scale = scale*fov

    if onScreen then
        SetTextScale(0.0*scale, 0.55*scale)
        SetTextFont(0)
        SetTextProportional(1)
        SetTextColour(r, g, b, 255)
        SetTextDropshadow(0, 0, 0, 0, 255)
        SetTextEdge(2, 0, 0, 0, 150)
        SetTextDropShadow()
        SetTextOutline()
        SetTextEntry("STRING")
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(_x,_y)
    end
end
