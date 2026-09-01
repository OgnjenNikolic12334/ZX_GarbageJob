local player = {} 

RegisterNetEvent("ZX_GarbageJob:ServerGarbageData")
AddEventHandler("ZX_GarbageJob:ServerGarbageData", function(playerRoute, playerState)
    if not Config.Routes[playerRoute] then
        return
    end

    if not playerState then
        return
    end

    if not player[source] then
        player[source] = {
            money = 0,
            route = playerRoute,
            state = playerState,
            trashCount = 0
        }
    end

end)

RegisterNetEvent("ZX_GarbageJob:DropTrash")
AddEventHandler("ZX_GarbageJob:DropTrash", function()
    if player[source] and player[source].trashCount < Config.GarbageStation.Vehicles.trashCount then
        player[source].money = player[source].money + Config.Routes[player[source].route].Rework.caunt
        player[source].trashCount = player[source].trashCount + 1

    else 
        return
    end

end)


RegisterNetEvent("ZX_GarbageJob:GiveRework")
AddEventHandler("ZX_GarbageJob:GiveRework", function()
    if player[source] and player[source].route then
        exports["ZX_Core"]:GiveItem(source, Config.Routes[player[source].route].Rework.item, player[source].money)
    end

    player[source] = nil
end)