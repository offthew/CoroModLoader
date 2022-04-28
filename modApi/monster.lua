local t = {}

function t:addTrait(monsterFamily,traitName,percentage)
  local oldTraits = monsterFamily.getTraitChanceObjects()
  table.insert(oldTraits,{percentage,traitName})
  function monsterFamily:getTraitChanceObjects()
    return oldTraits
  end
end

function t:removeTrait(monsterFamily,traitName)
  local oldTraits = monsterFamily.getTraitChanceObjects()
  for index,value in ipairs(oldTraits) do
    if(value[2]== traitName) then
      table.remove(oldTraits,index)
    end
  end
  function monsterFamily:getTraitChanceObjects()
    return oldTraits
  end
end

function t:addSkill(monsterFamily,skillName,unlockableLevel)
  local skillTree = monsterFamily.getSkillTree()
  table.insert(skillTree,{name=skillName,unlockedAt=unlockableLevel})
  function monsterFamily:getSkillTree()
    return skillTree
  end
end

function t:removeSkill(monsterFamily,skillName)
  local skillTree = monsterFamily.getSkillTree()
  for index,value in ipairs(skillTree) do
    if(value["name"]== skillName) then
      table.remove(skillTree,index)
    end
  end
  function monsterFamily:getSkillTree()
    return skillTree
  end
end
function t:editStat(monsterName,statName,value)
  local stats = monsterName.getBaseStats()
  stats[statName] = value
  function monsterName.getBaseStats()
    return stats
  end
end
return t