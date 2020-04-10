--[[

Copyright 2020 Zozo832 ( https://github.com/Zozo832 )

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

include("shared.lua")

local PANEL_VOTE = {}

function ENT:Initialize()
    self.CurrentAngle = Angle(0,0,90)


end

function ENT:Draw()

    self:DrawModel()


    if(math.Distance(LocalPlayer():GetPos().x, LocalPlayer():GetPos().z, self:GetPos().x, self:GetPos().z) > 350) then
        return 
    end

    cam.Start3D2D(self:GetPos() + Vector(0,0,50), Angle(0, self:GetAngles().y + 90, self:GetAngles().z + 90), 0.5)

    draw.DrawText("Liste électorale", "Trebuchet24", 0,0, Color(246,246,246), TEXT_ALIGN_CENTER)

    cam.End3D2D()
end

function PANEL_VOTE:Init()
    -- Top Bar
    self.MainPanel = vgui.Create("DPanel")
    self.MainPanel:SetSize(ScrW() / 2, ScrH() / 2)

    self.MainPanel.Paint = function(_,w,h)
        draw.RoundedBox(10,0,0, w,h, Color(246,246,246))
        draw.RoundedBoxEx(10,0,0,w,self.MainPanel:GetTall() * 0.15, Color(52, 152, 219), true, true)
    end

    self.MainPanel:Center()
    self.MainPanel:MakePopup()

    self.TitleLabel = vgui.Create("DLabel", self.MainPanel)
    self.TitleLabel:SetFont("Trebuchet24")
    self.TitleLabel:SetText("Vote (1er tour)")
    self.TitleLabel:SizeToContents()
    self.TitleLabel:SetPos(self.MainPanel:GetWide() * 0.05, ((self.MainPanel:GetTall() * 0.15) / 2) - self.TitleLabel:GetTall() / 2)
    self.TitleLabel:SetTextColor(Color(246,246,246))

    self.exitBtn = vgui.Create("DButton", self.MainPanel)
    self.exitBtn:SetSize(self.MainPanel:GetWide() * 0.1, self.MainPanel:GetTall() * 0.15)
    self.exitBtn:SetPos(self.MainPanel:GetWide() - self.exitBtn:GetWide(), 0)
    self.exitBtn:SetTextColor(Color(246,246,246))
    self.exitBtn:SetText("X")
    self.exitBtn:SetFont("Trebuchet24")
    self.exitBtn.Paint = function(_,w,h)

        if(self.exitBtn:IsHovered()) then

            draw.RoundedBoxEx(8,0,0,w,h,Color(192, 57, 43), false, true, false, false)
            return
        end

        draw.RoundedBoxEx(8,0,0,w,h,Color(231, 76, 60), false, true, false, false)
    end

    self.exitBtn.DoClick = function()


        self.MainPanel:SetVisible(false)
    end

    -- Main Panel -> inside box

    self.insideBoxPanel = vgui.Create("DPanel", self.MainPanel)
    self.insideBoxPanel:SetPos(0,self.MainPanel:GetTall() * 0.15)
    self.insideBoxPanel:SetSize(self.MainPanel:GetWide(),self.MainPanel:GetTall() - self.MainPanel:GetTall() * 0.15)
    self.insideBoxPanel:SetPaintBackground(false)

    -- Main Panel -> actions

    self.actionBar = vgui.Create("DPanel", self.insideBoxPanel)
    self.actionBar:SetSize(self.insideBoxPanel:GetWide(),self.insideBoxPanel:GetTall() * 0.2)
    self.actionBar:SetPaintBackground(false)

    self.registerBtn = vgui.Create("DButton", self.actionBar)
    self.registerBtn:SetSize(self.actionBar:GetWide() * 0.9, self.actionBar:GetTall() * 0.8)
    self.registerBtn:SetPos(self.actionBar:GetWide() / 2 - (self.registerBtn:GetWide() / 2), self.actionBar:GetTall() / 2 - (self.registerBtn:GetTall() / 2))
    self.registerBtn:SetText("S'inscrire aux élections")
    self.registerBtn:SetFont("Trebuchet24")
    self.registerBtn:SetTextColor(Color(246,246,246))
    self.registerBtn.DoClick = function()
        net.Start("VAPlayerRegistration")
        net.SendToServer()

        self.MainPanel:SetVisible(false)
    end
    self.registerBtn.Paint = function(_,w,h)

        if(self.registerBtn:IsHovered()) then
            draw.RoundedBox(4,0,0,w,h,Color(39, 174, 96))
            return
        end 

        draw.RoundedBox(4,0,0,w,h,Color(46, 204, 113))
    end
    -- Main panel -> inside box -> scroll cand

    self.candidateScroll = vgui.Create("DScrollPanel",self.insideBoxPanel)
    self.candidateScroll:SetSize(self.insideBoxPanel:GetWide(),self.insideBoxPanel:GetTall() * 0.8)
    self.candidateScroll:SetPos(0, self.actionBar:GetTall())
    -- Main panel -> inside box -> scroll cand -> list

    self.candidateList = vgui.Create("DIconLayout", self.candidateScroll)
    self.candidateList:SetSize(self.candidateScroll:GetWide(), self.candidateScroll:GetTall())
    self.candidateList:SetSpaceX((self.candidateList:GetWide() / 8) - self.candidateScroll:GetVBar():GetWide())
    self.candidateList:SetSpaceY(self.candidateList:GetTall() * 0.05)
    self.candidateList:SetBorder(self.candidateList:GetWide() * 0.025)
end

function PANEL_VOTE:UpdateNWInfos()

    local candidatesNumber = net.ReadUInt(7)

    if(candidatesNumber < 1) then return end

    for i = 1, candidatesNumber do
        
        table.insert(VAAddonSTATE.Candidates,i,{net.ReadString(), net.ReadUInt(8), net.ReadUInt(7)})

        local candidatePanel = self.candidateList:Add("DPanel")
        candidatePanel:SetSize((self.candidateList:GetWide() / 3.5) - self.candidateScroll:GetVBar():GetWide() - self.candidateList:GetBorder(), self.candidateList:GetTall() * 0.5)
        candidatePanel.Paint = function(_,w,h)
            draw.RoundedBoxEx(4,0,0,w,h * 0.2,Color(52, 73, 94),true,true)
        end

        local candidateName = vgui.Create("DLabel", candidatePanel)
        candidateName:SetText(VAAddonSTATE.Candidates[i][1])
        candidateName:SetFont("Trebuchet18")
        candidateName:SizeToContents()

        candidateName:SetPos(candidatePanel:GetWide() * 0.025, ((candidatePanel:GetTall() * 0.2) / 2) - candidateName:GetTall() / 2)

        local insidePanel = vgui.Create("DPanel", candidatePanel)
        insidePanel:SetPos(0, candidatePanel:GetTall() * 0.2)
        insidePanel:SetSize(candidatePanel:GetWide(), candidatePanel:GetTall() - (candidatePanel:GetTall() * 0.2))
        insidePanel:SetPaintBackground(false)

        insidePanel.Paint = function(_,w,h)
            draw.RoundedBoxEx(4,0,0,w,h,Color(246,246,246),false,false,true,true)
        end

        local voteBtn = vgui.Create("DButton", insidePanel)
        voteBtn:SetSize(insidePanel:GetWide(), insidePanel:GetTall() * 0.25)
        voteBtn:SetText("Voter")
        voteBtn:SetPos(0, insidePanel:GetTall() - voteBtn:GetTall())
        voteBtn:SetTextColor(Color(246,246,246))
        voteBtn.Paint = function(_,w,h)

            if(voteBtn:IsHovered()) then 

                draw.RoundedBoxEx(4,0,0,w,h,Color(39, 174, 96), false,false,true,true)

                return
            end

            draw.RoundedBoxEx(4,0,0,w,h,Color(46, 204, 113), false,false,true,true)
        end

        voteBtn.DoClick = function()

            net.Start("VAVoteMayor")
            net.WriteUInt(VAAddonSTATE.Candidates[i][2],8)
            net.SendToServer()
            self.MainPanel:SetVisible(false)

        end

        local votesLabel = vgui.Create("DLabel", insidePanel)
        votesLabel:SetText("Votes : " .. VAAddonSTATE.Candidates[i][3])
        votesLabel:SetFont("Trebuchet18")
        votesLabel:SizeToContents()

        votesLabel:SetTextColor(Color(0,0,0))
        votesLabel:SetPos(insidePanel:GetWide() * 0.05, ((insidePanel:GetTall() - voteBtn:GetTall() ) / 2) - (votesLabel:GetTall() / 2) )
    end




end

vgui.Register("VAVoteFirstTurnPanel", PANEL_VOTE)

net.Receive("VASendPanelFirstTurn", function(len)
    local m = vgui.Create("VAVoteFirstTurnPanel")
    m:UpdateNWInfos()

end)

local SECOND_VOTE_PANEL = {}

function SECOND_VOTE_PANEL:Init()

     -- Top Bar
     self.MainPanel = vgui.Create("DPanel")
     self.MainPanel:SetSize(ScrW() / 2, ScrH() / 2)
 
     self.MainPanel.Paint = function(_,w,h)
         draw.RoundedBox(10,0,0, w,h, Color(246,246,246))
         draw.RoundedBoxEx(10,0,0,w,self.MainPanel:GetTall() * 0.15, Color(52, 152, 219), true, true)
     end
 
     self.MainPanel:Center()
     self.MainPanel:MakePopup()
 
     self.TitleLabel = vgui.Create("DLabel", self.MainPanel)
     self.TitleLabel:SetFont("Trebuchet24")
     self.TitleLabel:SetText("Vote (2ème tour)")
     self.TitleLabel:SizeToContents()
     self.TitleLabel:SetPos(self.MainPanel:GetWide() * 0.05, ((self.MainPanel:GetTall() * 0.15) / 2) - self.TitleLabel:GetTall() / 2)
     self.TitleLabel:SetTextColor(Color(246,246,246))
 
     self.exitBtn = vgui.Create("DButton", self.MainPanel)
     self.exitBtn:SetSize(self.MainPanel:GetWide() * 0.1, self.MainPanel:GetTall() * 0.15)
     self.exitBtn:SetPos(self.MainPanel:GetWide() - self.exitBtn:GetWide(), 0)
     self.exitBtn:SetTextColor(Color(246,246,246))
     self.exitBtn:SetText("X")
     self.exitBtn:SetFont("Trebuchet24")
     self.exitBtn.Paint = function(_,w,h)
 
         if(self.exitBtn:IsHovered()) then
 
             draw.RoundedBoxEx(8,0,0,w,h,Color(192, 57, 43), false, true, false, false)
             return
         end
 
         draw.RoundedBoxEx(8,0,0,w,h,Color(231, 76, 60), false, true, false, false)
     end
 
     self.exitBtn.DoClick = function()
 
 
         self.MainPanel:SetVisible(false)
     end
 
     -- Main Panel -> inside box
 
     self.insideBoxPanel = vgui.Create("DPanel", self.MainPanel)
     self.insideBoxPanel:SetPos(0,self.MainPanel:GetTall() * 0.15)
     self.insideBoxPanel:SetSize(self.MainPanel:GetWide(),self.MainPanel:GetTall() - self.MainPanel:GetTall() * 0.15)
     self.insideBoxPanel:SetPaintBackground(false)

     self.finalistOne = vgui.Create("DPanel", self.insideBoxPanel)
     self.finalistOne:SetSize(self.insideBoxPanel:GetWide() / 3, self.insideBoxPanel:GetTall() * 0.9)
     self.finalistOne:SetPos(self.insideBoxPanel:GetWide() * 0.025, (self.insideBoxPanel:GetTall() / 2) - self.finalistOne:GetTall() / 2)
     self.finalistOne.Paint = function(_,w,h)

        draw.RoundedBoxEx(4,0,0,w,h * 0.15,Color(52, 152, 219), true,true)

     end

     self.finalistOneLbl = vgui.Create("DLabel", self.finalistOne)
     self.finalistOneLbl:SetFont("Trebuchet24")
     self.finalistOneLbl:SizeToContents()
     self.finalistOneLbl:SetPos(self.finalistOne:GetWide() * 0.05, ((self.finalistOne:GetTall() * 0.15) / 2) - self.finalistOneLbl:GetTall() / 2 )
     self.finalistOneLbl:SetTextColor(Color(246,246,246))


     self.finalistOneBtn = vgui.Create("DButton", self.finalistOne)
     self.finalistOneBtn:SetSize(self.finalistOne:GetWide(), self.finalistOne:GetTall() * 0.1)
     self.finalistOneBtn:SetPos(0,self.finalistOne:GetTall() - self.finalistOneBtn:GetTall())
     self.finalistOneBtn:SetText("Voter")
     self.finalistOneBtn:SetTextColor(Color(246,246,246))
     self.finalistOneBtn.DoClick = function()

        net.Start("VAVoteMayor")
        net.WriteBit(0)
        net.SendToServer()

        self.MainPanel:SetVisible(false)

     end
     self.finalistOneBtn.Paint = function(_,w,h)

        if(self.finalistOneBtn:IsHovered()) then 

            draw.RoundedBoxEx(4,0,0,w,h,Color(39, 174, 96), false,false,true,true)

            return
        end

        draw.RoundedBoxEx(4,0,0,w,h,Color(46, 204, 113), false,false,true,true)

     end

     self.insidePanelOne = vgui.Create("DPanel", self.finalistOne)
     self.insidePanelOne:SetPos(0,self.finalistOne:GetTall() * 0.15)
     self.insidePanelOne:SetSize(self.finalistOne:GetWide() , self.finalistOne:GetTall() - (self.finalistOne:GetTall() * 0.15) - (self.finalistOneBtn:GetTall()))


     self.finalistOneMdl = vgui.Create("DModelPanel", self.insidePanelOne)

     self.finalistOneMdl:SetSize(self.insidePanelOne:GetWide(), self.insidePanelOne:GetTall())

     function self.finalistOneMdl:LayoutEntity( Entity ) return end

     -- Finalist two

     self.finalistTwo = vgui.Create("DPanel", self.insideBoxPanel)
     self.finalistTwo:SetSize(self.insideBoxPanel:GetWide() / 3, self.insideBoxPanel:GetTall() * 0.9)
     self.finalistTwo:SetPos((self.insideBoxPanel:GetWide() * 0.8) - (self.finalistTwo:GetWide() / 2), (self.insideBoxPanel:GetTall() / 2) - self.finalistTwo:GetTall() / 2)
     self.finalistTwo.Paint = function(_,w,h)

        draw.RoundedBoxEx(4,0,0,w,h * 0.15,Color(52, 152, 219), true,true)

     end

     self.finalistTwoLbl = vgui.Create("DLabel", self.finalistTwo)
     self.finalistTwoLbl:SetFont("Trebuchet24")
     self.finalistTwoLbl:SetPos(self.finalistTwo:GetWide() * 0.05, ((self.finalistTwo:GetTall() * 0.15) / 2) - self.finalistTwoLbl:GetTall() / 2 )
     self.finalistTwoLbl:SetTextColor(Color(246,246,246))

     self.finalistTwoBtn = vgui.Create("DButton", self.finalistTwo)
     self.finalistTwoBtn:SetSize(self.finalistTwo:GetWide(), self.finalistTwo:GetTall() * 0.1)
     self.finalistTwoBtn:SetPos(0,self.finalistTwo:GetTall() - self.finalistTwoBtn:GetTall())
     self.finalistTwoBtn:SetText("Voter")
     self.finalistTwoBtn:SetTextColor(Color(246,246,246))

     self.finalistTwoBtn.DoClick = function()

        net.Start("VAVoteMayor")
        net.WriteBit(1)
        net.SendToServer()

        self.MainPanel:SetVisible(false)

     end
     self.finalistTwoBtn.Paint = function(_,w,h)

        if(self.finalistTwoBtn:IsHovered()) then 

            draw.RoundedBoxEx(4,0,0,w,h,Color(39, 174, 96), false,false,true,true)

            return
        end

        draw.RoundedBoxEx(4,0,0,w,h,Color(46, 204, 113), false,false,true,true)

     end

     self.insidePanelTwo = vgui.Create("DPanel", self.finalistTwo)
     self.insidePanelTwo:SetPos(0,self.finalistTwo:GetTall() * 0.15)
     self.insidePanelTwo:SetSize(self.finalistTwo:GetWide() , self.finalistTwo:GetTall() - (self.finalistTwo:GetTall() * 0.15) - (self.finalistTwoBtn:GetTall()))


     self.finalistTwoMdl = vgui.Create("DModelPanel", self.insidePanelTwo)

     self.finalistTwoMdl:SetSize(self.insidePanelTwo:GetWide(), self.insidePanelTwo:GetTall())

     function self.finalistTwoMdl:LayoutEntity( Entity ) return end

end

function SECOND_VOTE_PANEL:UpdateNWInfos()

    local finalistOneName = net.ReadString()
    local finalistOneModel = net.ReadString()

    local finalistTwoName = net.ReadString()
    local finalistTwoModel = net.ReadString()

    self.finalistOneLbl:SetText(finalistOneName)
    self.finalistOneLbl:SizeToContents()

    self.finalistOneMdl:SetModel(finalistOneModel)

    local bone = self.finalistOneMdl.Entity:LookupBone("ValveBiped.Bip01_Head1")

    local headPos = Vector(50,30,0), Angle(0,0,0)

    if(bone) then headPos = self.finalistOneMdl.Entity:GetBonePosition(bone) end
    
    self.finalistOneMdl:SetCamPos(headPos + Vector(15,5,-5))
    self.finalistOneMdl:SetLookAt(headPos)

    self.finalistTwoLbl:SetText(finalistTwoName)
    self.finalistTwoLbl:SizeToContents()
    
    self.finalistTwoMdl:SetModel(finalistTwoModel)


    bone = self.finalistTwoMdl.Entity:LookupBone("ValveBiped.Bip01_Head1")

    headPos = Vector(50,30,0), Angle(0,0,0)

    if(bone) then headPos = self.finalistTwoMdl.Entity:GetBonePosition(bone) end

    self.finalistTwoMdl:SetCamPos(headPos + Vector(15,5,-5))
    self.finalistTwoMdl:SetLookAt(headPos)

    
  
end

vgui.Register("VAVoteSecondTurnPanel", SECOND_VOTE_PANEL)

net.Receive("VASendPanelSecondTurn", function(len)

    local m = vgui.Create("VAVoteSecondTurnPanel")
    m:UpdateNWInfos()

end)
