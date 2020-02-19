--[[

Copyright 2020 Zozo832

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

--]]

AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")
-- Server
util.AddNetworkString("VASendPanelFirstTurn")
util.AddNetworkString("VASendPanelSecondTurn")
util.AddNetworkString("VAVoteMayor")
-- Client
util.AddNetworkString("VAPlayerRegistration")


-- Custom func
local function AntiNetSpam(ply)

    if(ply:GetNWBool("PERestrictAccess") != nil && ply:GetNWBool("PERestrictAccess") == true ) then return true end -- Spammer !

    if(ply:GetNWInt("PESpamProtection") == nil) then ply:SetNWInt("PESpamProtection", 1)
    
    -- Increment spam var
    elseif(ply:GetNWInt("PESpamProtection") != nil) then ply:SetNWInt("PESpamProtection", ply:GetNWInt("PESpamProtection") + 1)

    end

    -- If spamming
    if(ply:GetNWInt("PESpamProtection") >= 10) then

        ply:SetNWBool("PERestrictAccess", true)

        timer.Simple(60, function()

            ply:SetNWBool("PERestrictAccess", false)
            ply:SetNWInt("PESpamProtection", 0)

        end)
    end

    if(!timer.Exists("PESpamProtection"..ply:SteamID64())) then
        timer.Create("PESpamProtection"..ply:SteamID64(),1,1, function()

            ply:SetNWInt("PESpamProtection", ply:GetNWInt("PESpamProtection") - 1)

        end)

    else

        timer.Adjust("PESpamProtection"..ply:SteamID64(), 1, ply:GetNWInt("PESpamProtection"))

    end

    return false

end
-- End custom func

function ENT:Initialize()

    self:SetUseType(3)

    self:SetModel(VAAddonSTATE.BoardModel)
    self:SetSolid(SOLID_BBOX)

    self:DropToFloor()

end

function ENT:Use(a, caller, u, v)    


    if(VAAddonSTATE.SpamProtection == true && AntiNetSpam(caller)) then return end

    if(VAAddonSTATE.CurrentTurn == 0) then caller:ChatPrint("[Vote] Il n'y a pas d'élections pour le moment") return end

    if(VAAddonSTATE.CurrentTurn == 1) then

        net.Start("VASendPanelFirstTurn")

        net.WriteUInt(table.Count(VAAddonSTATE.Candidates), 7) -- Number of candidates 128 max

        if(table.Count(VAAddonSTATE.Candidates) > 0) then

            -- for each candidate send infos
            for _,candidate in pairs(VAAddonSTATE.Candidates) do 
                net.WriteString(tostring(candidate.ent:Nick()))
                net.WriteUInt(candidate.id, 8) -- 255 max
                net.WriteUInt(candidate.votes, 7) -- 128 max
            end

        end

        net.Send(caller)
    elseif(VAAddonSTATE.CurrentTurn == 2) then
        net.Start("VASendPanelSecondTurn")
        net.WriteString(tostring(VAAddonSTATE.Finalists[1].ent:Nick()))
        net.WriteString(VAAddonSTATE.Finalists[1].ent:GetModel())

        net.WriteString(tostring(VAAddonSTATE.Finalists[2].ent:Nick()))
        net.WriteString(VAAddonSTATE.Finalists[2].ent:GetModel())
        net.Send(caller)
    end

end


-- Player Disconnect or demoted handlers

local function gameEventsHandler(ply)

    if(ply:Team() == VAAddonSTATE.Job) then
        VAAddonSTATE.CurrentTurn = 1
    end

    -- check if election is running
    if(VAAddonSTATE.CurrentTurn < 1) then return end
    -- check if in elections
    if(VAAddonSTATE.Candidates[ply:AccountID()] != nil) then
        VAAddonSTATE.Candidates[ply:AccountID()] = nil
    end


end

hook.Add("PlayerDisconnected", "vaQuitHandler", function(ply) gameEventsHandler(ply) end)

hook.Add("demoteTeam", "vaDiesHandler", function(ply) gameEventsHandler(ply) end)

-- If mayor decides to quit his job
hook.Add("OnPlayerChangedTeam", "vaChangeHandler", function(ply, oldTeam, newTeam)

    if(oldTeam == VAAddonSTATE.Job) then 
        
        VAAddonSTATE.Candidates = {}
        VAAddonSTATE.Voters = {}
        VAAddonSTATE.CurrentTurn = 1 
    
    end

end)

-- Do not let player become mayor from f4 or /mayor

hook.Add("playerCanChangeTeam", "vaPlyCanJoinTeam", function(ply, team, forced)
    if(!forced && team == VAAddonSTATE.Job) then return false, "Vous devez vous faire élire, rendez-vous au tableau de vote" end
end)

-- end

-- first turn handler

hook.Add("VAStartedFirstTurnVote", "vaFirstTurnHandler", function()

    for _, ply in pairs(player.GetHumans()) do 

        ply:ChatPrint("[Vote] Les votes pour la prochaine élection ont débuté vous pouvez vous rendre à la mairie afin de voter pour le premier tour")

    end

end)

-- when player enters

net.Receive("VAPlayerRegistration", function(len, ply)

    if(VAAddonSTATE.SpamProtection == true && AntiNetSpam(ply)) then return end

    -- check spam prot net
    if(!IsValid(ply) || VAAddonSTATE.Candidates[ply:AccountID()] != nil || VAAddonSTATE.CurrentTurn != 1 ) then return end

    -- mapping -> id, entity, votes
    table.insert(VAAddonSTATE.Candidates, ply:AccountID(), {id = table.Count(VAAddonSTATE.Candidates) + 1, ent = ply, votes = 0})


    if(table.Count(VAAddonSTATE.Candidates) == 1 && !timer.Exists("VAFirstTurnTimer")) then
        -- first turn starts trigger
        hook.Run("VAStartedFirstTurnVote", VAAddonSTATE.Candidates[ply:AccountID()].ent)

        timer.Create("VAFirstTurnTimer", VAAddonSTATE.FirstTurnDuration, 1, function()
        
            -- after 5 minutes end it
            hook.Run("VAEndedFirstTurnVote", VAAddonSTATE.Candidates)

        end)

        timer.Start("VAFirstTurnTimer")

    end
end)

-- When first turn ended hook
hook.Add("VAEndedFirstTurnVote", "noticeEveryone", function(firstCandidate)

    if(table.Count(VAAddonSTATE.Candidates) == 0) then 
        -- flush
        VAAddonSTATE.Candidates = {}
        VAAddonSTATE.Voters = {}

        return 
    end

    if(table.Count(VAAddonSTATE.Candidates) == 1) then

        pid = nil

        for k in pairs(VAAddonSTATE.Candidates) do pid = k end

        if(!IsValid(VAAddonSTATE.Candidates[pid].ent)) then return end

        VAAddonSTATE.Candidates[pid].ent:changeTeam(VAAddonSTATE.Job, true)

        for _, ply in pairs(player.GetHumans()) do 

            ply:ChatPrint("[Vote] " .. tostring(VAAddonSTATE.Candidates[pid].ent:Nick()) .. " est désormais maire")

        end

        VAAddonSTATE.CurrentTurn = 0


         -- flush
         VAAddonSTATE.Candidates = {}
         VAAddonSTATE.Voters = {}

        return
    end

    VAAddonSTATE.Voters = {}
    VAAddonSTATE.CurrentTurn = 2

    tempTable = {}

    for k in pairs(VAAddonSTATE.Candidates) do

        table.insert(tempTable, VAAddonSTATE.Candidates[k])

    end

    VAAddonSTATE.Candidates = {}

    table.sort(tempTable, function(a,b) return a.votes > b.votes end  )

    if(!IsValid(tempTable[1].ent) || !IsValid(tempTable[2].ent) ) then return end

    VAAddonSTATE.Finalists[1] = tempTable[1]
    VAAddonSTATE.Finalists[2] = tempTable[2]

    VAAddonSTATE.Finalists[1].votes = 0
    VAAddonSTATE.Finalists[2].votes = 0 

    for _, ply in pairs(player.GetHumans()) do 

        ply:ChatPrint("[Vote] " .. tostring(VAAddonSTATE.Finalists[1].ent:Nick()) .. " et " .. tostring(VAAddonSTATE.Finalists[2].ent:Nick()) .. " sont désormais qualifiés pour le second tour, vous pouvez vous rendre à la mairie afin de voter pour l'un d'entre-eux")

    end

    hook.Run("VAStartedSecondTurn", VAAddonSTATE.Finalists)
-- modify timer time to 300 s + mayor to maire
    timer.Create("VASecondTurnTimer", VAAddonSTATE.SecondTurnDuration, 1, function()
        
        -- after 5 minutes end it
        hook.Run("VAEndedSecondTurnVote", VAAddonSTATE.Finalists)

    end)

    timer.Start("VASecondTurnTimer")

end)

-- second turn



-- vote handler
net.Receive("VAVoteMayor", function(len,ply)

    if(VAAddonSTATE.SpamProtection == true && AntiNetSpam(ply)) then return end

    if(table.HasValue(VAAddonSTATE.Voters, ply)) then return end -- already voted

    table.insert(VAAddonSTATE.Voters, ply)

    if(VAAddonSTATE.CurrentTurn < 1) then return end
    -- check if ply still exists in tbl
    if(VAAddonSTATE.CurrentTurn == 1) then 

        local voteID = net.ReadUInt(8)
    
        if(voteID < 1 || voteID > 255) then return end

        playerConcerned = nil

        for sid, candidateTBL in pairs(VAAddonSTATE.Candidates) do 
            if(VAAddonSTATE.Candidates[sid].id == voteID) then 
                playerConcerned = sid 
                break 
            end
            
        end

        if(playerConcerned == nil) then return end -- ply not found


        VAAddonSTATE.Candidates[playerConcerned].votes = VAAddonSTATE.Candidates[playerConcerned].votes + 1
    end

    if(VAAddonSTATE.CurrentTurn == 2) then

        local voteID = net.ReadBit()

        if(voteID < 0 || voteID > 1) then return end

        if(voteID == 0) then

            VAAddonSTATE.Finalists[1].votes = VAAddonSTATE.Finalists[1].votes + 1
            return

        end
        -- else
        VAAddonSTATE.Finalists[2].votes = VAAddonSTATE.Finalists[2].votes + 1

    end

end)

-- finally
hook.Add("VAEndedSecondTurnVote", "endingSecondTurn", function() 

    -- vallid checks
    if(!IsValid(VAAddonSTATE.Finalists[1].ent) && !IsValid(VAAddonSTATE.Finalists[2].ent) ) then VAAddonSTATE.CurrentTurn = 1 return end
    if(!IsValid(VAAddonSTATE.Finalists[1].ent) ) then
        VAAddonSTATE.Finalists[2].ent:changeTeam(VAAddonSTATE.Job, true) 
        return
    end

    if(!IsValid(VAAddonSTATE.Finalists[2].ent)) then
        VAAddonSTATE.Finalists[1].ent:changeTeam(VAAddonSTATE.Job, true) 
        return
    end

    -- end check

    local electedMayor = nil

    if(VAAddonSTATE.Finalists[1].votes == VAAddonSTATE.Finalists[2].votes) then electedMayor = VAAddonSTATE.Finalists[math.random(1,2)].ent

    elseif(VAAddonSTATE.Finalists[1].votes > VAAddonSTATE.Finalists[2].votes) then electedMayor = VAAddonSTATE.Finalists[1].ent

    else electedMayor = VAAddonSTATE.Finalists[2].ent end

    electedMayor:changeTeam(VAAddonSTATE.Job, true)
    VAAddonSTATE.CurrentTurn = 0

    -- flush
    VAAddonSTATE.Candidates = {}
    VAAddonSTATE.Voters = {}

    for _, ply in pairs(player.GetHumans()) do 

        ply:ChatPrint("[Vote] " .. tostring(electedMayor:Nick()) .. " est désormais Maire !")

    end


end)