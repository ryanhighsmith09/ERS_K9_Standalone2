
local k9 = nil
local following = false
local attacking = false
local menuOpen = false

local breeds = {'a_c_shepherd','a_c_rottweiler','a_c_husky','a_c_retriever'}
local currentBreed = 1

function MDTLog(msg)
    TriggerServerEvent('ers:k9:mdt', msg)
end

function Bodycam(msg)
    TriggerEvent('bodycam:record', 'K9 '..msg)
end

function K9BarkAnim()
    if not DoesEntityExist(k9) then return end
    RequestAnimDict('creatures@rottweiler@amb@world_dog_barking@base')
    while not HasAnimDictLoaded('creatures@rottweiler@amb@world_dog_barking@base') do Wait(0) end
    TaskPlayAnim(k9, 'creatures@rottweiler@amb@world_dog_barking@base', 'base', 8.0, -8.0, 1500, 1, 0, false, false, false)
    PlaySoundFromEntity(-1, 'bark', k9, '', false, 0)
    Wait(1500)
    ClearPedTasks(k9)
end

function ToggleK9()
    if DoesEntityExist(k9) then
        DeleteEntity(k9)
        k9 = nil
        MDTLog('dismissed')
        Bodycam('dismissed')
        return
    end

    local model = breeds[currentBreed]
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(0) end

    local ped = PlayerPedId()
    local c = GetOffsetFromEntityInWorldCoords(ped,0.0,2.0,0.0)
    k9 = CreatePed(28,model,c.x,c.y,c.z,GetEntityHeading(ped),true,true)
    SetEntityAsMissionEntity(k9,true,true)
    SetPedCanRagdoll(k9,false)
    SetBlockingOfNonTemporaryEvents(k9,true)

    following = true
    MDTLog('deployed')
    Bodycam('deployed')
end

function Follow() following=true attacking=false end
function Stay() following=false ClearPedTasks(k9) end

function Attack()
    local p,d = GetClosestPlayer()
    if p~=-1 and d<6.0 then
        TaskCombatPed(k9,GetPlayerPed(p),0,16)
        attacking=true
        MDTLog('bite')
        Bodycam('bite')
    end
end

function K9Vehicle()
    if not DoesEntityExist(k9) then return end

    if IsPedInAnyVehicle(k9, false) then
        TaskLeaveVehicle(k9, GetVehiclePedIsIn(k9, false), 0)
        return
    end

    local veh = GetVehiclePedIsIn(PlayerPedId(), false)
    if veh ~= 0 then
        K9BarkAnim()
        TaskEnterVehicle(k9, veh, 2000, 1, 1.0, 1, 0)
        MDTLog('vehicle entry')
        Bodycam('vehicle entry')
    end
end

RegisterNUICallback('radial', function(data, cb)
    if data.action=='spawn' then ToggleK9() end
    if data.action=='follow' then Follow() end
    if data.action=='stay' then Stay() end
    if data.action=='attack' then Attack() end
    if data.action=='vehicle' then K9Vehicle() end
    if data.action=='breed' then currentBreed=currentBreed%#breeds+1 end
    cb('ok')
end)

RegisterNUICallback('close', function(_, cb)
    menuOpen=false
    SetNuiFocus(false,false)
    SendNUIMessage({open=false})
    cb('ok')
end)

CreateThread(function()
    while true do
        Wait(0)
        if IsControlJustPressed(0,172) then
            menuOpen = not menuOpen
            SetNuiFocus(menuOpen,menuOpen)
            SendNUIMessage({open=menuOpen})
        end
        if menuOpen and IsControlJustPressed(0,177) then
            menuOpen=false
            SetNuiFocus(false,false)
            SendNUIMessage({open=false})
        end
    end
end)

CreateThread(function()
    while true do
        if menuOpen then
            DisableAllControlActions(0)
            EnableControlAction(0,177,true)
            Wait(0)
        else
            Wait(500)
        end
    end
end)

CreateThread(function()
    while true do
        Wait(1000)
        if DoesEntityExist(k9) and following then
            TaskGoToEntity(k9,PlayerPedId(),-1,2.0,3.0,1073741824,0)
        end
    end
end)

function GetClosestPlayer()
    local ply=PlayerPedId()
    local pc=GetEntityCoords(ply)
    local cp,cd=-1,999.0
    for _,v in ipairs(GetActivePlayers()) do
        local p=GetPlayerPed(v)
        if p~=ply then
            local d=#(pc-GetEntityCoords(p))
            if d<cd then cd=d cp=v end
        end
    end
    return cp,cd
end
