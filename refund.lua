    /*
        ["class de l'entity/weapons"] = LaValeur
    */
    local Bible = {
        ["sent_ball"] = 100,
        ["manhack_welder"] = 800
    }
    // être sur que les entités despawn ( normalement pas besoin au darkrp )
    local prevent = true
    // durer avant de perde le remboursement
    local time = 5 * 60

if SERVER then
    local tmp
    util.AddNetworkString("RemboursementNotif")
    if not file.Exists("Remboursement/","Data") then
        file.CreateDir("Remboursement")
    end
end
hook.Add("PlayerSpawn","init val",function(ply)
    if file.Exists("Remboursement/"..ply:SteamID64()..".txt","Data") then
        ply.RemboursementValue = file.Read("Remboursement/"..ply:SteamID64()..".txt","Data")
        tmp = ply.RemboursementValue
        net.Start("RemboursementNotif")
        net.WriteString("refund application valide")
        net.Send(ply)
        timer.Simple(time,function()
            ply.RemboursementValue = ply.RemboursementValue - tmp
            net.Start("RemboursementNotif")
            net.WriteString("no refund availible")
            net.WriteString(tostring(tmp))
            net.Send(ply)
        end)
    else
        ply.RemboursementValue = 0
    end
end)
hook.Add("PlayerDisconnected","save val",function(ply)
    if ply.RemboursementValue == 0 then return false end
    file.Write("Remboursement/"..ply:SteamID64()..".txt",ply.RemboursementValue)
end)
hook.Add("PlayerSpawnSENT","add",function(ply, class)
    if Bible[class] then
        ply.RemboursementValue = ply.RemboursementValue + Bible[class]
    end
end)
hook.Add("EntityRemoved","remove",function(ent)
    if CLIENT then return false end
    local class = ent:GetClass()
    local ply = ent:CPPIGetOwner()
    if not IsValid(ply) then return false end
    if Bible[class] then
        ply.RemboursementValue = ply.RemboursementValue - Bible[class]
    end
end)
hook.Add( "WeaponEquip", "weapon check", function(swep,ply)
    if Bible[swep:GetClass()] then
        ply.RemboursementValue = ply.RemboursementValue + Bible[swep:GetClass()]
    end
end)
hook.Add("PlayerDroppedWeapon", "weapon uncharge",function(ply,swep)
    if Bible[swep:GetClass()] then
        ply.RemboursementValue = ply.RemboursementValue - Bible[swep:GetClass()]
    end
end)
hook.Add("PlayerSay","commande",function(ply,text)
    if text == "/remboursement" then
        net.Start("RemboursementNotif")
        net.WriteString("info")
        net.WriteString(tostring(ply.RemboursementValue))
        net.Send(ply)
        return ""
    end
    local args = string.Split(text," ")
    if args[1] ~= "/remboursement" then return false end
    if not ply:IsSuperAdmin() then return "Vous devez être superadmi" end
    for _,v in ipairs(player.GetAll()) do
        local name = string.Split(v:getDarkRPVar("rpname")," ")
        if string.lower(name[1]) ~= string.lower(args[2]) then continue end
        net.Start("RemboursementNotif")
        if v.RemboursementValue == 0 then
            net.WriteString("no value")
            net.WriteEntity(v)
            net.Send(ply)
        else
            net.WriteString("refund action")
            net.WriteEntity(ply)
            net.WriteEntity(v)
            net.WriteString(tostring(v.RemboursementValue))
            net.Broadcast()
            v:addMoney(v.RemboursementValue)
            v.RemboursementValue,tmp = 0,0
            if not prevent then return end
            for _,ent in ipairs(ents.GetAll()) do
                if IsValid(ent) && ent:CPPIGetOwner() == v then
                    ent:Remove()
                end
            end
        end
    end
    return ""
end)
if CLIENT then
    net.Receive("RemboursementNotif",function()
        local action = net.ReadString()
        if action == "refund application valide" then
            chat.AddText(Color(255,255,255),"Vous êtes",
            Color(0,150,0)," illigible ",
            Color(255,255,255),"a un remboursement. Veuillez contacter un",
            Color(150,0,150)," Administrateur",
            Color(50,175,175)," 5 minutes pour la réclamation")
        end
        if action == "refund action" then
            local admin = net.ReadEntity()
            local target = net.ReadEntity()
            local val = net.ReadString()
            chat.AddText(Color(150,0,150),admin:getDarkRPVar("rpname"),
            Color(255,255,255)," viens de ",
            Color(0,0,150),"rembourser ",
            Color(0,150,0),target:getDarkRPVar("rpname"),
            Color(255,255,255)," pour un montant total de ",
            Color(150,0,0),val,
            Color(255,255,255),"$")
        end
        if action == "no refund availible" then
            local val = net.ReadString()
            chat.AddText(Color(255,255,255),"Vous n'êtes pus",
            Color(150,0,0)," illigible ",
            Color(255,255,255),"a un remboursement. Vous avez perdu ",
            Color(50,175,175),val,
            Color(255,255,255),"$")
        end
        if action == "no value" then
            local target = net.ReadEntity()
            chat.AddText(Color(0,150,0),target:getDarkRPVar("rpname"),
            Color(255,255,255)," ne peux pas être rembourser")
        end
        if action == "info" then
            local val = net.ReadString()
            chat.AddText(Color(255,255,255),"Vous avez ",
            Color(150,0,150),val,
            Color(255,255,255),"$ de remboursement possible")
        end
        if action == "save data" then
            if not LocalPlayer():IsAdmin() then return false end
            chat.AddText(Color(255,255,255),"les données du système de remboursement en était sauvegarder")
        end
    end)
end

if SERVER then
    timer.Create("save data",15*60,0,function()
        for _,v in ipairs(player.GetAll()) do
            file.Write("Remboursement/"..v:SteamID64()..".txt",v.RemboursementValue)
        end
        net.Start("RemboursementNotif")
        net.WriteString("save data")
        net.Broadcast()
    end)
end


print("Remboursement System was been load!")