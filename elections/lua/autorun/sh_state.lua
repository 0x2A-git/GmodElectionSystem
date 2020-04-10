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

VAAddonSTATE = {}

if SERVER then

    -- /!\ Do not touch any of these variables /!\

    -- 0 = None, 1 = first, 2 = second
    VAAddonSTATE.CurrentTurn = 1

    VAAddonSTATE.Voters = {}
    VAAddonSTATE.Finalists = {}


end

hook.Add("DarkRPDBInitialized", "VASetup", function()

    -- CONFIGURATION IS ONLY DONE IN THIS HOOK

    -- Change to the name of your mayor's job
    VAAddonSTATE.Job = TEAM_MAYOR

    -- In seconds
    VAAddonSTATE.FirstTurnDuration = 120;

    -- In seconds
    VAAddonSTATE.SecondTurnDuration = 60;

    VAAddonSTATE.BoardModel = "models/props_lab/corkboard001.mdl"

    VAAddonSTATE.SpamProtection = true;

end)

VAAddonSTATE.Candidates = {
}
