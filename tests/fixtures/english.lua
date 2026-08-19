-- Fixture: an unambiguously Latin-script buffer.
local function greet(name)
  return string.format("hello %s, this is ordinary left to right source", name)
end

return greet
