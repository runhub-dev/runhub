local hs = {}
hs.status = "Progressing"
hs.message = ""
if obj.status ~= nil then
  if obj.status.health ~= nil then
    if obj.status.health.status ~= nil then
      hs.status = obj.status.health.status
    end
    if obj.status.health.message ~= nil then
      hs.message = obj.status.health.message
    end
  end
end
return hs
