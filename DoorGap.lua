local car = ac.getCar(0)

-- Recording state
local recording = false
local frames = {}
local timer = 0
local INTERVAL = 1 / 30  -- 30 Hz

-- Debug visualization state
local showDebug = false
local dbgPos  = {}  -- vec3 cache of recorded positions
local dbgLook = {}  -- vec3 cache of recorded look dirs

local function rebuildDebugCache()
  dbgPos  = {}
  dbgLook = {}
  for i, f in ipairs(frames) do
    dbgPos[i]  = vec3(f.pos.x,  f.pos.y,  f.pos.z)
    dbgLook[i] = vec3(f.look.x, f.look.y, f.look.z)
  end
end

-- 3D world overlay
function script.draw3D()
  if not showDebug or #dbgPos == 0 then return end

  render.setDepthMode(render.DepthMode.Off)

  local n       = #dbgPos
  local camNorm = -ac.getCameraForward()  -- always face the camera
  local dotStep   = math.max(1, math.floor(n / 300))
  local arrowStep = math.max(1, math.floor(n / 60))

  -- Red path dots (dense trail)
  for i = 1, n, dotStep do
    render.circle(dbgPos[i], camNorm, 0.3, rgbm(1, 0.2, 0.2, 0.9))
  end

  -- Cyan position markers (bigger ring)
  for i = 1, n, arrowStep do
    render.circle(dbgPos[i], camNorm, 0.6, rgbm(0, 0.7, 1, 0.3), rgbm(0, 0.7, 1, 1))
  end

  -- Yellow dot 1.5 m ahead = look direction indicator
  for i = 1, n, arrowStep do
    render.circle(dbgPos[i] + dbgLook[i] * 1.5, camNorm, 0.2, rgbm(1, 1, 0, 1))
  end
end

local function v3(v)
  return { x = v.x, y = v.y, z = v.z }
end

-- Minimal JSON encoder (numbers, booleans, tables/arrays)
local function json(val)
  local t = type(val)
  if t == 'number'  then return string.format('%.6g', val) end
  if t == 'boolean' then return val and 'true' or 'false' end
  if t == 'table' then
    if #val > 0 then
      local p = {}
      for _, v in ipairs(val) do p[#p+1] = json(v) end
      return '[' .. table.concat(p, ',') .. ']'
    else
      local p = {}
      for k, v in pairs(val) do p[#p+1] = '"' .. k .. '":' .. json(v) end
      return '{' .. table.concat(p, ',') .. '}'
    end
  end
  return 'null'
end

local saveStatus = ''

local function saveRecording()
  local path = ac.getFolder(ac.FolderID.Root) .. '\\run1.json'
  io.save(path, json(frames))
  saveStatus = string.format('Saved %d frames → run1.json', #frames)
end

function script.windowMain(dt)
  local speedKmh = car.speedKmh
  local rpm      = car.rpm
  local maxRpm   = car.rpmLimiter
  local gear     = car.gear
  local throttle = car.gas
  local brake    = car.brake
  local turbo    = car.turboBoost

  ui.text(string.format('Speed:    %.1f km/h', speedKmh))

  ui.text(string.format('RPM:      %d / %d', math.floor(rpm), math.floor(maxRpm)))
  local rpmRatio = maxRpm > 0 and (rpm / maxRpm) or 0
  local rpmColor = rpmRatio > 0.9 and rgbm(1, 0.1, 0.1, 1) or rpmRatio > 0.75 and rgbm(1, 0.8, 0, 1) or rgbm(0.2, 0.8, 0.2, 1)
  ui.progressBar(rpmRatio, vec2(-1, 8), '', rpmColor)

  local gearStr = gear == 0 and 'N' or gear == -1 and 'R' or tostring(gear)
  ui.text(string.format('Gear:     %s', gearStr))

  ui.text('Throttle:')
  ui.sameLine(0, 4)
  ui.progressBar(throttle, vec2(-1, 12), '', rgbm(0.2, 0.8, 0.2, 1))

  ui.text('Brake:   ')
  ui.sameLine(0, 4)
  ui.progressBar(brake, vec2(-1, 12), '', rgbm(0.9, 0.2, 0.2, 1))

  if turbo > 0.01 then
    ui.text(string.format('Turbo:    %.2f bar', turbo))
  end

  ui.separator()

  if not recording then
    if ui.button('Start Recording', vec2(-1, 0)) then
      recording = true
      frames = {}
      timer = 0
      saveStatus = ''
    end
    if saveStatus ~= '' then
      ui.textColored(saveStatus, rgbm(0.3, 1, 0.3, 1))
    end
    if #dbgPos > 0 then
      ui.separator()
      if ui.checkbox('Show Path  (' .. #dbgPos .. ' pts)', showDebug) then
        showDebug = not showDebug
      end
    end
  else
    ui.textColored(string.format('● REC  %d frames', #frames), rgbm(1, 0.25, 0.25, 1))
    if ui.button('Stop & Save  →  run1.json', vec2(-1, 0)) then
      recording = false
      saveRecording()
      rebuildDebugCache()
    end
  end
end

function script.update(dt)
  if not recording then return end
  timer = timer + dt
  if timer >= INTERVAL then
    timer = timer - INTERVAL
    table.insert(frames, {
      pos   = v3(car.position),
      look  = v3(car.look),
      vel   = v3(car.velocity),
      steer = car.steer,
      gas   = car.gas,
    })
  end
end
