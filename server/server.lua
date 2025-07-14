local QBCore = exports['qb-core']:GetCoreObject()

RegisterServerEvent("hugo-korsan:odemeVeAlarm", function(label)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local amount = math.random(Config.Payment.min, Config.Payment.max)
    Player.Functions.AddMoney("cash", amount, "korsan-teslimat")
    TriggerClientEvent("QBCore:Notify", src, "+"..amount.."Dolar aldın", "success")

    if math.random(1, 100) <= 20 then
        local coords = GetEntityCoords(GetPlayerPed(src))
        for _, id in pairs(QBCore.Functions.GetPlayers()) do
            local xPlayer = QBCore.Functions.GetPlayer(id)
            if xPlayer and xPlayer.PlayerData.job.name == "police" then
                TriggerClientEvent("QBCore:Notify", id, "Korsan teslimatı yapıldı: " .. label, "error")
                TriggerClientEvent("SetNewWaypoint", id, coords.x, coords.y)
            end
        end
    end
end)