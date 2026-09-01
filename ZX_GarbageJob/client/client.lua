local spawnedBossPed = nil

local trashModels = {} 

local garbages = {
    objects = {},
    collected = {}
}

local targets = {
    boss = nil
}

local playerState = {
    garbageJobBlipHandle = nil,
    interaction = false,
    visibleTextUi = false,
    isCreaatedWaitingForPickupVehicleMarker = false,
    waitingVehicleMarker = nil,
    jobState = "civil",
    proccessState = "idle",
    routeState = "not_on_route",
    vehicle = nil,
    garbageJobBlip = nil,
    routeBlip = nil,
    handleBlip = nil,
    blipZoneId = nil,
    route = nil,
    carriedProp = nil,
    textUiDropTrashInVehicleIsVisible = false,
    dropGarbageTarget = nil,
    dropTrashInVehicleMarker = nil,
    isOpenTrunk = false,
    lastMarkerUpdate = 0,
    trashCount = 0
}

-----
--| Pomocne Funkcije
-----

local function printHelperText(time, text)
    ClearPrints()

    BeginTextCommandPrint("STRING") 
    AddTextComponentSubstringPlayerName(text) 
    EndTextCommandPrint(time, 1) 

end

local function AttachGarbageToPlayer(ped)
    local prop = GetHashKey(Config.RoutesSettings.GettingTrash.prop[1])
    RequestModel(prop)

    while not HasModelLoaded(prop) do
        Wait(20)
    end

    local coords = GetEntityCoords(ped)

    local garbageProp = CreateObject(
        prop, 
        coords.x, 
        coords.y, 
        coords.z, 
        true, 
        true, 
        false
    )

    local boneIndex = GetPedBoneIndex(ped, 28422)

    AttachEntityToEntity(
        garbageProp, 
        ped, 
        boneIndex, 
        -0.013916015625, 0.00013884915097151, 0.020900152623653,    
        1.3931584358215,  1.7133742570877, -2.-39.79008102417,   
        true, true, false, true, 1, true
    )

    playerState.carriedProp = garbageProp
end

local function SetRoute()
    if playerState.proccessState ~= "go_to_garbage" then 
        return
    end

    if playerState.route then
        return
    end

    local routesNumber = #Config.Routes

    local rendomRoute = math.random(1, routesNumber)

    if not rendomRoute then 
        return
    end

    if not playerState.routeBlip then
        local blipId, handle = exports["ZX_Core"]:AddBlip({
            coords = Config.Routes[rendomRoute].Zone.coords,
            sprite = Config.RoutesSettings.Blip.sprite,
            scale = Config.RoutesSettings.Blip.scale,
            colour = Config.RoutesSettings.Blip.colour,
            text = Locales.garbageRouteBlipText
        })

        playerState.routeBlip = blipId
        playerState.handleBlip = handle

    end

    if not playerState.blipZoneId then

        local blipZoneId = AddBlipForRadius(
            Config.Routes[rendomRoute].Zone.coords.x, 
            Config.Routes[rendomRoute].Zone.coords.y, 
            Config.Routes[rendomRoute].Zone.coords.z, 
            Config.Routes[rendomRoute].Zone.distance
        )

        SetBlipColour(blipZoneId, Config.RoutesSettings.Zone.colour)
        SetBlipAlpha(blipZoneId, 128)

        playerState.blipZoneId = blipZoneId

    end

    SetBlipRoute(playerState.handleBlip, true)
    SetBlipRouteColour(playerState.handleBlip, Config.RoutesSettings.Blip.colour)

    playerState.route = rendomRoute

    TriggerServerEvent("ZX_GarbageJob:ServerGarbageData", playerState.route, playerState.jobState)

    if Config.RoutesSettings.ShowHelperText then
        printHelperText(6000, Locales.helperTextGoToRoute)
    end

    playerState.proccessState = "on_garbage_route"

end

local function SpawnWorkVehicle()
    local vehicle = GetHashKey(Config.GarbageStation.Vehicles.model)

    if not IsModelValid(vehicle) then
        return
    end

    RequestModel(vehicle)

    while not HasModelLoaded(vehicle) do
        Wait(10)
    end

    local coord = Config.GarbageStation.Vehicles.spawnCoords

    local workVehicle = CreateVehicle(
        vehicle,
        coord.x,
        coord.y,
        coord.z,
        coord.w,
        true,
        true
    )

    playerState.vehicle = workVehicle

    playerState.proccessState = "waiting_for_pickup_vehicle" 
end

local function RestartRoute()

    ClearPrints()

    if playerState.waitingVehicleMarker then
        exports["ZX_Core"]:RemoveMarker(playerState.waitingVehicleMarker)

        playerState.waitingVehicleMarker = nil
    end

    if playerState.blipZoneId then
        RemoveBlip(playerState.blipZoneId) 
    end

    if playerState.routeBlip then
        exports["ZX_Core"]:RemoveBlip(playerState.routeBlip)
    end

    playerState.blipZoneId = nil
    playerState.routeBlip = nil
    playerState.route = nil
    playerState.handleBlip = nil

    playerState.jobState = "civil"
    playerState.proccessState = "idle"
    playerState.routeState = "not_on_route"
    playerState.route = nil
    playerState.lastMarkerUpdate = 0
    playerState.trashCount = 0

    garbages.collected = {}
    garbages.objects = {}

    playerState.isCreaatedWaitingForPickupVehicleMarker = false
end

local function CancleGarbageDuty()  
    if not DoesEntityExist(playerState.vehicle) then
        exports["ZX_Core"]:ShowNotify(Locales.cancleGarbageDutyNotifyTitle, Locales.cancleGarbageDutyNotifyDescription, "warning")

        RestartRoute()

        return
    end

    if playerState.waitingVehicleMarker then
        exports["ZX_Core"]:RemoveMarker(playerState.waitingVehicleMarker)

        playerState.waitingVehicleMarker = nil
    end

    local vehicleCoords = GetEntityCoords(playerState.vehicle)
    local vehicleParkingCoords = vector3(Config.GarbageStation.Vehicles.spawnCoords.x, Config.GarbageStation.Vehicles.spawnCoords.y, Config.GarbageStation.Vehicles.spawnCoords.z)
    local distance = #(vehicleCoords - vehicleParkingCoords)

    if distance > Config.GarbageStation.Vehicles.distanceParking then
        RestartRoute()

        exports["ZX_Core"]:ShowNotify(Locales.cantPutVehicleOnParkingNotifyTitle, Locales.cantPutVehicleOnParkingNotifyDescription, "error")

        DeleteVehicle(playerState.vehicle)
        return
    end
    
    exports["ZX_Core"]:ShowNotify(Locales.cancleWorkNotifyTitle, Locales.cancleWorkNotifyDescription, "success")

    RestartRoute()

    DeleteVehicle(playerState.vehicle)

    TriggerServerEvent("ZX_GarbageJob:GiveRework")

end

local function ShowAlertDialog()
    if playerState.jobState == "civil" then
        local alertDialogCivil = lib.alertDialog({
            header = Locales.alertDialogCivilHeader,
            content = Locales.alertDialogCivilText,
            centered = true,
            cancel = true
        })

        if alertDialogCivil == "confirm" then
            playerState.jobState = "worker"
            SpawnWorkVehicle()
            exports["ZX_Core"]:ShowNotify(Locales.startWorkNotifyTitle, Locales.startWorkNotifyDescription, "success")
        end

    elseif playerState.jobState == "worker" then
        local alertDialogWorker = lib.alertDialog({
            header = Locales.alertDialogWorkerHeader,
            content = Locales.alertDialogWorkerText,
            centered = true,
            cancel = true
        })

        if alertDialogWorker == "confirm" then
            CancleGarbageDuty()
        end
    end
end

local function SetupEntityTarget(data)
    if Config.Settings.Interaction.type == "ox_target" then
        exports.ox_target:addLocalEntity(data.entity, {
            {
                name = data.name,
                label = data.label,
                distance = data.distance,
                icon =  data.icon,
                onSelect = function()
                    data.onSelect()
                end
            }
        })

        if data.boss then
            targets.boss = data.name
        end

    elseif Config.Settings.Interaction.type == "qb-target" then
        exports['qb-target']:AddTargetEntity(data.entity, {
            options = {
                {
                    icon = data.icon,
                    label = data.label,
                    action = function()
                        data.onSelect()
                    end,
                }
            },
            distance = data.distance
        }) 

        if data.boss then
            targets.boss = data.label
        end
    end
end

local function StartBossAnimation(bossModel)

    RequestAnimDict(Config.GarbageStation.Boss.animations.dict)

    while not HasAnimDictLoaded(Config.GarbageStation.Boss.animations.dict) do
        Wait(10)
    end

    TaskPlayAnim(
        bossModel,
        Config.GarbageStation.Boss.animations.dict,
        Config.GarbageStation.Boss.animations.name,
        8.0,
        -8.0,
        -1,
        49,
        0,
        false,
        false,
        false
    )   

end

local function SpawnBossPed()

    local bossModel = GetHashKey(Config.GarbageStation.Boss.model)

    if not IsModelValid(bossModel) then
        print("WARNING: Invalid boss model: " .. Config.GarbageStation.Boss.model)
        return
    end

    RequestModel(bossModel)

    while not HasModelLoaded(bossModel) do
        Wait(10)
    end

    local boss = CreatePed(
		4, 
		bossModel, 
		Config.GarbageStation.Boss.coords.x, 
		Config.GarbageStation.Boss.coords.y, 
		Config.GarbageStation.Boss.coords.z, 
		Config.GarbageStation.Boss.heading, 
		false, 
		false
	)

    FreezeEntityPosition(boss, true)
    SetEntityInvincible(boss, true)
    SetBlockingOfNonTemporaryEvents(boss, true)

    StartBossAnimation(boss)

    spawnedBossPed = boss

end

local function GetingTrashAnimation(ped)
    RequestAnimDict(Config.RoutesSettings.GettingTrash.animations.dict)

    while not HasAnimDictLoaded(Config.RoutesSettings.GettingTrash.animations.dict) do
        Wait(10)
    end

    TaskPlayAnim(
        ped,
        Config.RoutesSettings.GettingTrash.animations.dict,
        Config.RoutesSettings.GettingTrash.animations.name, 
        8.0,
        -8.0,
        -1,
        0,
        0,
        false,
        false,
        false
    )   

    Wait(100)

    while IsEntityPlayingAnim(ped, Config.RoutesSettings.GettingTrash.animations.dict, Config.RoutesSettings.GettingTrash.animations.name, 3) do 
        Wait(100)
    end
end

local function CarryTrashAnimation(ped)

    RequestAnimDict(Config.RoutesSettings.CarryTrashAnimation.dict)

    while not HasAnimDictLoaded(Config.RoutesSettings.CarryTrashAnimation.dict) do
        Wait(20)
    end

    TaskPlayAnim(
        ped,
        Config.RoutesSettings.CarryTrashAnimation.dict,
        Config.RoutesSettings.CarryTrashAnimation.name,
        8.0,
        -8.0,
        -1,
        49,
        0,
        false,
        false,
        false
    )   
end

local function GetingTrashProces(index)
    if playerState.trashCount >= Config.GarbageStation.Vehicles.trashCount then
        return
        
    end

    local object = garbages.objects[index]

    if not object then 
        return 
    end

    GetingTrashAnimation(PlayerPedId())

    local id = tostring(GetEntityCoords(object.entity))
    garbages.collected[id] = true

    if Config.Settings.Interaction.type == "ox_target" then
        exports.ox_target:removeLocalEntity(object.entity, object.name)

    elseif Config.Settings.Interaction.type == "qb-target" then
        exports['qb-target']:RemoveTargetEntity(object.entity, Locales.targetLabelGetGarbage)
    end

    exports["ZX_Core"]:RemoveMarker(object.markerId)
    garbages.objects[index] = nil

    local ped = PlayerPedId()

    CarryTrashAnimation(ped)

    AttachGarbageToPlayer(ped)

end

local function ProccessBossPed(playerPedId)
    local playerCoords = GetEntityCoords(playerPedId)
    local distance = #(playerCoords - Config.GarbageStation.Boss.coords)

    if distance < Config.GarbageStation.Boss.distance then
        if not spawnedBossPed then
            SpawnBossPed()

            if not playerState.interaction then
                SetupEntityTarget({
                    boss = true,
                    entity = spawnedBossPed, 
                    name = "boss_ped",
                    label = Locales.targetLabel,
                    distance = Config.Settings.Interaction.distance,
                    icon =  Config.Settings.Interaction.targetIconBoss,
                    onSelect = function()
                        ShowAlertDialog()
                    end
                })
                playerState.interaction = true
            end

        end

    elseif distance > Config.GarbageStation.Boss.distance and spawnedBossPed then
        DeleteEntity(spawnedBossPed)
        spawnedBossPed = nil
        playerState.interaction = false

    end

    if Config.Settings.Interaction.type == "textUi" then
        if distance < Config.Settings.Interaction.distance then
            if not playerState.visibleTextUi then 
                lib.showTextUI(Locales.textUiLabel)
                playerState.visibleTextUi = true
            end

        end

        if distance > Config.Settings.Interaction.distance and playerState.visibleTextUi then
            lib.hideTextUI()
            playerState.visibleTextUi = false
        end
    end
end

local function WaitForPickupVehicleMarker(sleep)

    if playerState.proccessState ~= "waiting_for_pickup_vehicle" then
        return
    end

    local vehicleCoords = GetEntityCoords(playerState.vehicle)
    local vehicleMarkerCoords = vehicleCoords + vector3(0.0, 0.0, 4.0)

    if playerState.isCreaatedWaitingForPickupVehicleMarker == false then 
        local vehicleMarker = exports["ZX_Core"]:AddMarker({
            type = Config.GarbageStation.Vehicles.marker.type,
            coords = vehicleMarkerCoords,
            size = Config.GarbageStation.Vehicles.marker.size,
            color = {
                r = Config.GarbageStation.Vehicles.marker.color.r,
                g = Config.GarbageStation.Vehicles.marker.color.g,
                b = Config.GarbageStation.Vehicles.marker.color.b,
                a = Config.GarbageStation.Vehicles.marker.color.a
            },
            distance = Config.GarbageStation.Vehicles.marker.distance    
        })

        playerState.waitingVehicleMarker = vehicleMarker

        playerState.isCreaatedWaitingForPickupVehicleMarker = true 

    end

    if Config.RoutesSettings.ShowHelperText then
        printHelperText(sleep + 1, Locales.helperTextGoToVehicle)
    end

    if playerState.isCreaatedWaitingForPickupVehicleMarker == true then 
        exports["ZX_Core"]:UpdateMarker(playerState.waitingVehicleMarker, {
            coords = vehicleMarkerCoords
        })
    end

    local nowVehicle = GetVehiclePedIsIn(playerPedId, false)

    if nowVehicle ~= 0 and nowVehicle == playerState.vehicle then

        if playerState.waitingVehicleMarker then
            exports["ZX_Core"]:RemoveMarker(playerState.waitingVehicleMarker)

            ClearPrints()

            playerState.waitingVehicleMarker = nil
            playerState.proccessState = "go_to_garbage"
        end
    end
end

local function GetTrashHash()
    for _, trash in ipairs(Config.RoutesSettings.TrashModels) do
        trashModels[GetHashKey(trash)] = true
    end    
end

local function ProccessRouteObject(object, trashId)
    local entityModel = GetEntityModel(object)
    if trashModels[entityModel] then
        local objectCoords = GetEntityCoords(object)
        local distanceZone = #(Config.Routes[playerState.route].Zone.coords - objectCoords)

        if distanceZone <= Config.Routes[playerState.route].Zone.distance then

            playerState.routeState = "on_route"

            local garbageMarker = exports["ZX_Core"]:AddMarker({
                type = Config.RoutesSettings.GarbageMarker.type,
                coords = objectCoords + Config.RoutesSettings.GarbageMarker.height,
                size = Config.RoutesSettings.GarbageMarker.size,
                color = {
                    r = Config.RoutesSettings.GarbageMarker.color.r,
                    g = Config.RoutesSettings.GarbageMarker.color.g,
                    b = Config.RoutesSettings.GarbageMarker.color.b,
                    a = Config.RoutesSettings.GarbageMarker.color.a
                },
                distance = Config.RoutesSettings.GarbageMarker.distance    
            })

            garbages.objects[object] = {
                id = trashId,
                name = "garbage_" .. object,  
                entity = object,    
                markerId = garbageMarker
            }

        end
    end
end

local function ProccessRouteInteraction()
    if playerState.proccessState ~= "on_garbage_route" then
        return

    end

    local playerCoords = GetEntityCoords(PlayerPedId())

    local distance = #(Config.Routes[playerState.route].Zone.coords - playerCoords)

    if distance > Config.Routes[playerState.route].Zone.distance then
        playerState.routeState = "not_on_route"

        for index, objectt in pairs(garbages.objects) do 
            if Config.Settings.Interaction.type == "ox_target" then

                exports.ox_target:removeLocalEntity(objectt.entity, objectt.name)
            elseif Config.Settings.Interaction.type == "qb-target" then

                exports['qb-target']:RemoveTargetEntity(objectt.entity, Locales.targetLabelGetGarbage)
            end

            exports["ZX_Core"]:RemoveMarker(objectt.markerId)
            garbages.objects[index] = nil

        end

        return

    elseif playerState.routeState == "on_route" then
        return
    end

    local allObject = GetGamePool("CObject")

    for k, object in pairs(allObject) do

        local trashId = tostring(GetEntityCoords(object))

        if not garbages.collected[trashId] then
            ProccessRouteObject(object, trashId)
        end
    end
        
    if Config.Settings.Interaction.type == "textUi" then
        return
    end

    for index, garbage in pairs(garbages.objects) do

        if not garbages.collected[garbage.id] then
            SetupEntityTarget({
                entity = garbage.entity, 
                name = garbage.name,
                label = Locales.targetLabelGetGarbage,
                distance = Config.Settings.Interaction.distance,
                icon =  Config.Settings.Interaction.targetIconGarbage,
                onSelect = function()
                    GetingTrashProces(index)

                end
            })        
        end
    end
end

local function HandleGarbageInteractionTextUi(closestEntityIndex)
    if not playerState.visibleTextUi then
        lib.showTextUI(Locales.textUiLabelGetGarbage)
        playerState.visibleTextUi = true
    end

    if IsControlJustReleased(0, 38) then 
        GetingTrashProces(closestEntityIndex)
    end 
end

local function DisableActions()
    if Config.RoutesSettings.DisableActions.jump then
        DisableControlAction(0, 22, true)

    end

    if Config.RoutesSettings.DisableActions.attack then
        DisableControlAction(0, 24, true)

    end

    if Config.RoutesSettings.DisableActions.aim then
        DisableControlAction(0, 25, true)

    end

    if Config.RoutesSettings.DisableActions.run then
        DisableControlAction(0, 21, true)
    end
end

local function DropTrashInVehicleAnimation(ped)
    ClearPedTasksImmediately(ped)
    
    RequestAnimDict(Config.RoutesSettings.DropTrashInVehicleAnimation.dict)

    while not HasAnimDictLoaded(Config.RoutesSettings.DropTrashInVehicleAnimation.dict) do
        Wait(20)
    end

    TaskPlayAnim(
        ped,
        Config.RoutesSettings.DropTrashInVehicleAnimation.dict,
        Config.RoutesSettings.DropTrashInVehicleAnimation.name,
        8.0,
        -8.0,
        -1,
        49,
        0,
        false,
        false,
        false
    )   

    Wait(20)
    
    while IsEntityPlayingAnim(ped, Config.RoutesSettings.GettingTrash.animations.dict, Config.RoutesSettings.GettingTrash.animations.name, 3) do 
        Wait(100)
    end

end

local function DropTrashProcess()
    local ped = PlayerPedId()

    DropTrashInVehicleAnimation(ped)

    Wait(600)

    ClearPedTasksImmediately(ped)
    DetachEntity(playerState.carriedProp, true, true)
    DeleteEntity(playerState.carriedProp)
    playerState.carriedProp = nil

    Wait(200)
    SetVehicleDoorShut(playerState.vehicle, 5, false)

    playerState.trashCount = playerState.trashCount + 1

    exports["ZX_Core"]:ShowNotify(Locales.trashCountNotifyTitle, Locales.trashCountNotifyDescription .. playerState.trashCount .. " / " .. Config.GarbageStation.Vehicles.trashCount, "info")
            
    if playerState.dropTrashInVehicleMarker then
        exports["ZX_Core"]:RemoveMarker(playerState.dropTrashInVehicleMarker)
        playerState.dropTrashInVehicleMarker = nil
    end

    if Config.Settings.Interaction.type == "textUi" and playerState.textUiDropTrashInVehicleIsVisible == true then 
        lib.hideTextUI()
        playerState.textUiDropTrashInVehicleIsVisible = false
    end

    if Config.Settings.Interaction.type == "ox_target" and playerState.dropGarbageTarget ~= nil then
        exports.ox_target:removeLocalEntity(playerState.vehicle, playerState.dropGarbageTarget)
        playerState.dropGarbageTarget = nil

    elseif Config.Settings.Interaction.type == "qb-target" and playerState.dropGarbageTarget ~= nil then
        exports['qb-target']:RemoveTargetEntity(playerState.vehicle, playerState.dropGarbageTarget)
        playerState.dropGarbageTarget = nil

    end

    TriggerServerEvent("ZX_GarbageJob:DropTrash")

    if playerState.trashCount >= Config.GarbageStation.Vehicles.trashCount then
        if playerState.routeBlip then
            exports["ZX_Core"]:RemoveBlip(playerState.routeBlip)
        end

        if playerState.blipZoneId then 
            RemoveBlip(playerState.blipZoneId) 
        end

        for index, object in pairs(garbages.objects) do
            if object.markerId then
                exports["ZX_Core"]:RemoveMarker(object.markerId)
            end

            if object.entity and object.name then
                if Config.Settings.Interaction.type == "ox_target" then
                    exports.ox_target:removeLocalEntity(object.entity, object.name)

                elseif Config.Settings.Interaction.type == "qb-target" then
                    exports['qb-target']:RemoveTargetEntity(object.entity, object.name)
                end
                garbages.objects[index] = nil
            end
        end
        
        if DoesBlipExist(playerState.garbageJobBlipHandle) then
            ClearAllBlipRoutes()
            SetBlipRoute(playerState.garbageJobBlipHandle, true)
            SetBlipRouteColour(playerState.garbageJobBlipHandle, 5)
        end

        exports["ZX_Core"]:ShowNotify(Locales.returnTrackNotifyTitle, Locales.returnTrackNotifyDescription, "success")
    end
end

local function DropTrashInVehicle()

    local markerCoords = GetOffsetFromEntityInWorldCoords(playerState.vehicle, 0.0, -5.5, 0.0)

    if not playerState.dropTrashInVehicleMarker then

        local marker = exports["ZX_Core"]:AddMarker({
            type = Config.RoutesSettings.DropTrashInVehicle.marker.type,
            coords = markerCoords,
            size = Config.RoutesSettings.DropTrashInVehicle.marker.size,
            color = {
                r = Config.RoutesSettings.DropTrashInVehicle.marker.color.r,
                g = Config.RoutesSettings.DropTrashInVehicle.marker.color.g,
                b = Config.RoutesSettings.DropTrashInVehicle.marker.color.b,
                a = Config.RoutesSettings.DropTrashInVehicle.marker.color.a
            },
            distance = Config.RoutesSettings.DropTrashInVehicle.marker.distance    
        })

        playerState.dropTrashInVehicleMarker = marker
    
    end

    if playerState.dropTrashInVehicleMarker then
        local currentTime = GetGameTimer()
 
        if playerState.lastMarkerUpdate and currentTime - playerState.lastMarkerUpdate <= 600 then
            playerState.lastMarkerUpdate = currentTime
            exports["ZX_Core"]:UpdateMarker(playerState.dropTrashInVehicleMarker, {
                coords = markerCoords
            })

        end
    end

    local ped = PlayerPedId()
    local playerCoords = GetEntityCoords(ped)

    local distance = #(playerCoords - markerCoords)

    if distance <= Config.Settings.Interaction.distance then
        if Config.Settings.Interaction.type == "textUi" and playerState.textUiDropTrashInVehicleIsVisible == false then 
            lib.showTextUI(Locales.textUiLabelDropTrashInVehicle)
            playerState.textUiDropTrashInVehicleIsVisible = true
        end

        if not playerState.isOpenTrunk then
            SetVehicleDoorOpen(playerState.vehicle, 5, false, false)
            playerState.isOpenTrunk = true
        end

        if IsControlJustReleased(0, 38) then
            DropTrashProcess()
        end

    elseif distance > Config.Settings.Interaction.distance then
        if Config.Settings.Interaction.type == "textUi" and playerState.textUiDropTrashInVehicleIsVisible == true then 
            lib.hideTextUI()
            playerState.textUiDropTrashInVehicleIsVisible = false
        end

        if playerState.isOpenTrunk then

            SetVehicleDoorShut(playerState.vehicle, 5, false)
            playerState.isOpenTrunk = false
        end
    end

    if Config.Settings.Interaction.type == "ox_target" and playerState.dropGarbageTarget == nil then
        local targetName = "drop_garbage"
        exports.ox_target:addLocalEntity(playerState.vehicle, {
            {
                name = targetName,
                label = Locales.targetLabelDropTrashInVehicle,
                distance = Config.Settings.Interaction.distance,
                icon =  Config.Settings.Interaction.targetIconGarbage,      
                bones = { "boot", "taillight_l", "taillight_r" },
                onSelect = function()
                    DropTrashProcess()
                end
            }
        })   
        playerState.dropGarbageTarget = targetName

    elseif Config.Settings.Interaction.type == "qb-target" and playerState.dropGarbageTarget == nil then
        exports['qb-target']:AddTargetEntity(playerState.vehicle, {
            options = {
                {
                    type = "client",
                    icon = Config.Settings.Interaction.targetIconGarbage,
                    label = Locales.targetLabelDropTrashInVehicle,
                    action = function(entity)
                        DropTrashProcess()
                    end,
                    bones = { "boot", "taillight_l", "taillight_r" }, 
                }
            },
            distance = Config.Settings.Interaction.distance
        })

        playerState.dropGarbageTarget = Locales.targetLabelDropTrashInVehicle
    end
end

-----
--| Glavne Funkcije
-----

AddEventHandler("onResourceStop", function(resourceName)
    if resourceName ~= GetCurrentResourceName() then
        return

    end

    if playerState.garbageJobBlip then
        exports["ZX_Core"]:RemoveBlip(playerState.garbageJobBlip)

    end

    if playerState.blipZoneId then
        RemoveBlip(playerState.blipZoneId) 

    end
    
    if playerState.routeBlip then
        exports["ZX_Core"]:RemoveBlip(playerState.routeBlip)

    end

    if garbages.objects and next(garbages.objects) then
        for _, key in pairs(garbages.objects) do
            if Config.Settings.Interaction.type == "ox_target" then
                exports.ox_target:removeLocalEntity(key.entity, targets.boss)

            elseif Config.Settings.Interaction.type == "qb-target" then
                exports['qb-target']:RemoveTargetEntity(key.entity, targets.boss)
            end

            if key.markerId then
                exports["ZX_Core"]:RemoveMarker(key.markerId)
            end
        end
    end

    if playerState.waitingVehicleMarker then
        exports["ZX_Core"]:RemoveMarker(playerState.waitingVehicleMarker)

    end

    if targets.boss then
        if Config.Settings.Interaction.type == "ox_target" then
            exports.ox_target:removeLocalEntity(spawnedBossPed, targets.boss)

        elseif Config.Settings.Interaction.type == "qb-target" then
            exports['qb-target']:RemoveTargetEntity(spawnedBossPed, targets.boss)

        end
    end

    if DoesEntityExist(spawnedBossPed) then
        DeleteEntity(spawnedBossPed)
    end
end)

-----
--| Thread
-----

CreateThread(function()
    if not playerState.garbageJobBlip then
        local blip = Config.GarbageStation.Boss.blip

        local blipId, handle = exports["ZX_Core"]:AddBlip({
            coords = Config.GarbageStation.Boss.coords,
            sprite = blip.sprite,
            scale = blip.scale,
            colour = blip.colour,
            text = Locales.garbageJobBlipText
        })

        playerState.garbageJobBlip = blipId
        playerState.garbageJobBlipHandle = handle
    end

    while true do
        playerPedId = PlayerPedId()
        local sleep = 1000
        
        ProccessBossPed(playerPedId)

        Wait(sleep)
    end
end)

CreateThread(function()
    if Config.Settings.Interaction.type == "textUi" then 

        while true do 
            local closestDistance = 999999.0
            local closestEntity = nil
            local closestEntityIndex = nil

            local sleep = 1000
            local coords = GetEntityCoords(playerPedId)
            local distance1 = #(coords - Config.GarbageStation.Boss.coords)

            if distance1 < Config.Settings.Interaction.distance then
                sleep = 0
                if IsControlJustReleased(0, 38) then
                    ShowAlertDialog()
                end

            end

            if playerState.routeState == "on_route" then
                sleep = 500

                for index, garbage in pairs(garbages.objects) do 
                    local distance2 = #(coords - GetEntityCoords(garbage.entity))

                    if distance2 <= Config.Settings.Interaction.distance then

                        if distance2 < closestDistance then
                            closestDistance = distance2
                            closestEntity = garbage
                            closestEntityIndex = index

                        end
                    end
                end 

                if closestEntity and garbages.collected[tostring(GetEntityCoords(closestEntity))] ~= true then
                    sleep = 0

                    HandleGarbageInteractionTextUi(closestEntityIndex)

                elseif playerState.visibleTextUi then 
                    lib.hideTextUI()
                    playerState.visibleTextUi = false
                end 
            end

            Wait(sleep)
        end
    end
end)

CreateThread(function()
    GetTrashHash()

    while true do
        local sleep = 500 

        WaitForPickupVehicleMarker(sleep)

        SetRoute()

        ProccessRouteInteraction()

        if playerState.carriedProp then  
            sleep = 0
            DropTrashInVehicle()
        end 

        Wait(sleep)
    end
end)

CreateThread(function()
    while true do
        local sleep = 700

        if playerState.carriedProp then
            sleep = 0
            DisableActions()

        end

        Wait(sleep)
    end
end)
