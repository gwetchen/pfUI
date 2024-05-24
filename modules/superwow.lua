-- Compatibility layer to use castbars provided by SuperWoW:
-- https://github.com/balakethelock/SuperWoW
pfUI:RegisterModule("superwow", "vanilla", function ()
  local unitcast = CreateFrame("Frame")
  unitcast:RegisterEvent("UNIT_CASTEVENT")
  unitcast:SetScript("OnEvent", function()
    if arg3 == "START" or arg3 == "CAST" or arg3 == "CHANNEL" then
      -- human readable argument list
      local guid = arg1
      local target = arg2
      local event_type = arg3
      local spell_id = arg4
      local timer = arg5
      local start = GetTime()

      -- get spell info from spell id
      local spell, icon, rank
      if SpellInfo and SpellInfo(spell_id) then
        spell, rank, icon = SpellInfo(spell_id)
      end

      -- set fallback values
      spell = spell or UNKNOWN
      icon = icon or "Interface\\Icons\\INV_Misc_QuestionMark"

      -- add cast action to the database
      if not libcast.db[guid] then libcast.db[guid] = {} end
      libcast.db[guid].cast = spell
      libcast.db[guid].rank = nil
      libcast.db[guid].start = GetTime()
      libcast.db[guid].casttime = timer
      libcast.db[guid].icon = icon
      libcast.db[guid].channel = event_type == "CHANNEL" or false

      local duration, playerGUID, _
      if spell and rank then
        duration = libdebuff:GetDuration(spell, rank)
        print(duration .. "  " .. target)
      end
      _, playerGUID = UnitExists("player")


      --if spell == "Mind Blast" then duration = 1 end

      --[[local shadowSpells = {
        ["Mind Flay"] = nil,
        ["Shadow Word: Pain"] = nil,
        ["Mind Blast"] = nil,
      }

      if UnitClass("player") == "Priest" then
        local _,_,_,_,count = GetTalentInfo(3,11)
        if shadowSpells[spell] and count == 5 then
          libdebuff:AddPending(nil, 0, "Shadow Vulnerability", 15, target)
        end
      end]]--


      if guid == playerGUID then  --if player casted the spell we can check for resists
        libdebuff:AddPending(nil, 0, spell, duration, target)  
      else                        --if another player casted the spell we can not check for resists and will have to assume the spell hit
        if not libdebuff.objects[target] then libdebuff.objects[target] = {} end --Unitlevel seems to be used for differentiating targets therefore no use looking it up every time here
        if not libdebuff.objects[target][0] then libdebuff.objects[target][0] = {} end
        if not libdebuff.objects[target][0][spell] then libdebuff.objects[target][0][spell] = {} end
        libdebuff.objects[target][0][spell].effect = spell
        libdebuff.objects[target][0][spell].start_old = libdebuff.objects[target][0][spell].start
        libdebuff.objects[target][0][spell].start = GetTime()
        --libdebuff.objects[target][0][spell].rank = rank --not used for anything right now, can remove if no usecase found
        libdebuff.objects[target][0][spell].duration = libdebuff:GetDuration(spell, rank)
      end
      

      -- write state variable
      superwow_active = true
    elseif arg3 == "FAIL" then
      local guid = arg1

      -- delete all cast entries of guid
      if libcast.db[guid] then
        libcast.db[guid].cast = nil
        libcast.db[guid].rank = nil
        libcast.db[guid].start = nil
        libcast.db[guid].casttime = nil
        libcast.db[guid].icon = nil
        libcast.db[guid].channel = nil
      end
    end
  end)
end)