--[[ This Source Code Form is subject to the terms of the Mozilla Public
License, v. 2.0. If a copy of the MPL was not distributed with this
file, You can obtain one at https://mozilla.org/MPL/2.0/. ]]

---@diagnostic disable
local xplr = xplr
---@diagnostic enable

local P = {}
P.name = 'ctx4'

xplr.fn.custom[P.name] = {}
local fn_ctx = xplr.fn.custom[P.name]
fn_ctx.hooks = {}

local function lerr(msg)
  print(string.format('error: %s: %s', P.name, msg))
end

local default_style = {
  { fg = 'Green', add_modifiers = { 'Bold', 'Underlined' } },
  { fg = 'Yellow', add_modifiers = { 'Bold', 'Underlined' } },
  { fg = 'Blue', add_modifiers = { 'Bold', 'Underlined' } },
  { fg = 'Red', add_modifiers = { 'Bold', 'Underlined' } },
  empty = { fg = 'Reset' },
  current = { add_modifiers = { 'Bold', 'Reversed' } },
  reverse_current = true,
}

local State = {}
function State:init()
  local instance = {
    current = 1,
    ctx = { {}, {}, {}, {} },
    style = default_style,
    title = 'Ctx',
  }
  self.__index = self
  return setmetatable(instance, self)
end
local _s

function State:get_ctx(n)
  if n < 1 or n > 4 then
    return
  end
  return self.ctx[n]
end

function State:is_open(n)
  if n < 1 or n > 4 then
    return
  end
  return self.ctx[n].pwd and true or false
end

function State:is_empty(n)
  if n < 1 or n > 4 then
    return
  end
  return not self.ctx[n].pwd and true or false
end

function State:set_current(n, pwd, focused_path)
  if n < 1 or n > 4 then
    return
  end
  self.current = n
  if pwd then
    self.ctx[n].pwd = pwd
  end
  if focused_path then
    self.ctx[n].focused = focused_path
  end
end

function State:set_current_pwd(pwd)
  if pwd then
    self.ctx[self.current].pwd = pwd
  end
end

function State:set_current_focus(path)
  if path then
    self.ctx[self.current].focused = path
  end
end

function State:clear(n)
  if n < 1 or n > 4 then
    return
  end
  self.ctx[n] = {}
end

function State:next_ctx_num(from)
  if from == 4 then
    return 1
  end
  return from + 1
end

function State:prev_ctx_num(from)
  if from == 1 then
    return 4
  end
  return from - 1
end

function State:next_open_ctx_num()
  local n = self:next_ctx_num(self.current)
  for _ = 1, 3 do
    if self:is_open(n) then
      return n
    end
    n = self:next_ctx_num(n)
  end
end

function State:prev_open_ctx_num()
  local n = self:prev_ctx_num(self.current)
  for _ = 1, 3 do
    if self:is_open(n) then
      return n
    end
    n = self:prev_ctx_num(n)
  end
end

function State:next_empty_ctx_num()
  local n = self:next_ctx_num(self.current)
  for _ = 1, 3 do
    if self:is_empty(n) then
      return n
    end
    n = self:next_ctx_num(n)
  end
end

function State:draw()
  local t = {}
  for i, _ in ipairs(self.ctx) do
    local c = tostring(i)
    if i == self.current and self.style.reverse_current then
      local style = {}
      style.fg = self.style[i].fg
      style.add_modifiers = self.style.current.add_modifiers
      c = xplr.util.paint(c, style)
    elseif i == self.current then
      c = xplr.util.paint(c, self.style.current)
    elseif self:is_empty(i) then
      c = xplr.util.paint(c, self.style.empty)
    else
      c = xplr.util.paint(c, self.style[i])
    end
    table.insert(t, c)
  end
  return t
end

local function switch_messages(n)
  local ctx = _s:get_ctx(n)
  if not ctx then
    return {
      { LogError = string.format('%s: context `%s` not found', P.name, n) },
    }
  end
  local msgs = {
    { ChangeDirectory = ctx.pwd },
  }
  if ctx.focused then
    table.insert(msgs, { FocusPath = ctx.focused })
  else
    table.insert(msgs, 'FocusFirst')
  end
  return msgs
end

-- Switch to the next open context
-- If there is no other context open yet, open the next one
-- and switch to it
fn_ctx.next = function(app)
  local next = _s:next_open_ctx_num()
  if next then
    _s:set_current(next)
    return switch_messages(next)
  end
  next = _s:next_ctx_num(_s.current)
  _s:set_current(next, app.pwd)
  return { 'FocusFirst' }
end

-- Switch to the previous open context
-- If there is an empty context, switch to it
fn_ctx.prev = function(app)
  local n = _s:next_empty_ctx_num()
  if n then
    _s:set_current(n, app.pwd)
    return { 'FocusFirst' }
  end
  local prev = _s:prev_ctx_num(_s.current)
  _s:set_current(prev)
  return switch_messages(prev)
end

-- Switch to the given context, if not yet open, open it
local function switch_to(pwd, n)
  if _s:is_open(n) then
    _s:set_current(n)
    return switch_messages(n)
  end
  _s:set_current(n, pwd)
  return { 'FocusFirst' }
end

-- Close the current context and switch to the previous one
-- If it is the last context, quit
fn_ctx.close = function(_)
  local _current = _s.current
  local prev = _s:prev_open_ctx_num()
  if prev then
    _s:set_current(prev)
    _s:clear(_current)
    return switch_messages(prev)
  end
  return { 'Quit' }
end

fn_ctx.ui = function(_)
  local row = _s:draw()
  return {
    CustomTable = {
      ui = { title = { format = _s.title } },
      widths = {
        { Length = 1 },
        { Length = 1 },
        { Length = 1 },
        { Length = 1 },
      },
      col_spacing = 1,
      body = {
        row,
      },
    },
  }
end

-- ## hooks
fn_ctx.hooks.on_load = function(app)
  if not _s then
    _s = State:init()
  end
  _s:set_current(1, app.pwd)
end

fn_ctx.hooks.on_pwd_change = function(app)
  _s:set_current_pwd(app.pwd)
end

fn_ctx.hooks.on_focus_change = function(app)
  if app.focused_node then
    _s:set_current_focus(app.focused_node.absolute_path)
  end
end
-- hooks ##

local function setup_keys(kmap)
  kmap = kmap and kmap or {}
  local default_keymap = {
    next = 'tab',
    prev = 'back-tab',
    close = 'q',
    switch_to_1 = '1',
    switch_to_2 = '2',
    switch_to_3 = '3',
    switch_to_4 = '4',
  }
  local keymap = {}
  for k, v in pairs(default_keymap) do
    keymap[k] = kmap[k] and kmap[k] or v
  end

  local helpmap = {
    next = 'switch to next context',
    prev = 'switch to previous context',
    close = 'close the current context or quit',
    switch_to_1 = 'switch to context 1',
    switch_to_2 = 'switch to context 2',
    switch_to_3 = 'switch to context 3',
    switch_to_4 = 'switch to context 4',
  }

  local d = xplr.config.modes.builtin.default
  for fn, key in pairs(keymap) do
    d.key_bindings.on_key[key] = {
      help = helpmap[fn],
      messages = {
        { CallLuaSilently = 'custom.' .. P.name .. '.' .. fn },
      },
    }
  end
end

P.get_current_context_num = function()
  return _s.current
end

P.get_current_context_style = function()
  return _s.style[_s.current]
end

P.get_contexts = function()
  return _s.ctx
end

P.setup = function(config)
  if not _s then
    _s = State:init()
  end
  if config.context_styles then
    if #config.context_styles > 4 then
      lerr('contexts_style must contains 4 style objects')
    else
      for i, style in ipairs(config.context_styles) do
        _s.style[i] = style
      end
    end
  end
  if config.empty_style then
    _s.style.empty = config.empty_style
  end
  if config.current_style then
    _s.style.current = config.current_style
  end
  if config.reverse_current_style then
    _s.style.reverse_current = config.current_style
  end
  setup_keys(config.keymap)
  if config.no_title then
    _s.title = nil
  end
  if config.title then
    _s.title = config.title
  end

  -- for each context create a switch_to_n function
  for n, _ in ipairs(_s.ctx) do
    fn_ctx['switch_to_' .. n] = function(app)
      return switch_to(app.pwd, n)
    end
  end
end

return P
