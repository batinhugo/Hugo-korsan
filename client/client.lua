local QBCore = exports['qb-core']:GetCoreObject()
local isDelivering, deliveryBlip, deliveryIndex, deliveryLabel, carryingProp = false, nil, nil, nil, nil

-- NPC oluşturma ve görev başlatma
CreateThread(function()
    local model = GetHashKey(Config.NPC.model)
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(0) end

    local ped = CreatePed(0, model, Config.NPC.coords.x, Config.NPC.coords.y, Config.NPC.coords.z - 1.0, Config.NPC.coords.w, false, false)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)

exports['qb-target']:AddTargetEntity(ped, {
    options = {
        {
            icon = "fas fa-dolly",
            label = "Teslimat Al (Korsan Satıcı)",
            action = function()
                if isDelivering then
                    QBCore.Functions.Notify("Zaten teslimatın var!", "error")
                    return
                end
                deliveryIndex = math.random(#Config.DeliveryPoints)
                deliveryLabel = Config.Items[math.random(#Config.Items)]
                SetDeliveryBlip(deliveryIndex)
                GiveCarryItem()
                SpawnDeliveryNPC()
                QBCore.Functions.Notify(deliveryLabel .. " teslimatı için yola çık!", "primary")
                isDelivering = true
            end
        },
        {
            icon = "fas fa-times",
            label = "Teslimatı İptal Et",
            action = function()
                CancelDelivery()
            end,
            canInteract = function()
                return isDelivering
            end
        }
    },
    distance = 2.5
})
end)

-- Teslimat NPC'si oluştur
function SpawnDeliveryNPC()
    local pos = Config.DeliveryPoints[deliveryIndex]
    local model = GetHashKey("s_m_y_dealer_01")
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(0) end

    local npc = CreatePed(0, model, pos.x, pos.y, pos.z - 1.0, 0.0, false, false)
    FreezeEntityPosition(npc, true)
    SetEntityInvincible(npc, true)
    SetBlockingOfNonTemporaryEvents(npc, true)

    exports['qb-target']:AddTargetEntity(npc, {
        options = {{
            icon = "fas fa-box",
            label = "Teslim Et",
            action = function() DeliverPackage(npc) end
        }},
        distance = 2.0
    })
end

-- Teslim işlemi
function DeliverPackage(npc)
    local ped = PlayerPedId()
    ClearPedTasks(ped)
    TaskStartScenarioInPlace(ped, "PROP_HUMAN_BUM_BIN", 0, true) -- teslim animasyonu
    QBCore.Functions.Progressbar("teslim_et", "Teslim Ediliyor...", 3000, false, true, {}, {}, {}, {}, function()
        ClearPedTasks(ped)
        DeleteEntity(npc)
        if carryingProp then DeleteObject(carryingProp) end
        TriggerServerEvent("hugo-korsan:odemeVeAlarm", deliveryLabel)
        if deliveryBlip then RemoveBlip(deliveryBlip) end
        deliveryIndex, deliveryLabel, carryingProp, isDelivering = nil, nil, nil, false
    end)
end

function GiveCarryItem()
    local ped = PlayerPedId()
    local model = GetHashKey("prop_cardbordbox_03a")
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(10) end

    carryingProp = CreateObject(model, GetEntityCoords(ped), true, true, false)

    -- El kemiğine uygun şekilde attach et
    AttachEntityToEntity(carryingProp, ped, GetPedBoneIndex(ped, 28422), 
        0.00, -0.40, -0.30, 00.0, 0.0, 800.0, true, true, false, true, 1, true)

    -- Animasyon
    RequestAnimDict("anim@heists@box_carry@")
    while not HasAnimDictLoaded("anim@heists@box_carry@") do Wait(10) end
    TaskPlayAnim(ped, "anim@heists@box_carry@", "idle", 8.0, -8, -1, 50, 0, false, false, false)
end



-- Teslimat blip
function SetDeliveryBlip(index)
    local coords = Config.DeliveryPoints[index]
    deliveryBlip = AddBlipForCoord(coords)
    SetBlipSprite(deliveryBlip, 408)
    SetBlipColour(deliveryBlip, 1)
    SetBlipScale(deliveryBlip, 0.8)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Teslimat Noktası")
    EndTextCommandSetBlipName(deliveryBlip)
end
-- teslimat iptal
function CancelDelivery()
    local ped = PlayerPedId()

    if deliveryBlip then RemoveBlip(deliveryBlip) end
    if carryingProp then DeleteObject(carryingProp) end

    ClearPedTasks(ped)
    deliveryBlip = nil
    deliveryIndex = nil
    deliveryLabel = nil
    carryingProp = nil
    isDelivering = false

    QBCore.Functions.Notify("Teslimat iptal edildi.", "error")
end