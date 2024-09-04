## ctx4.xplr

Intuitive context switcher plugin for [xplr](https://github.com/sayanarijit/xplr)

### Usage

There are 4 contexts, intended to be used in default mode

- `tab` to cycle through open contexts
- `S-tab` to cycle backward or open new context
- `q` to close the current context (or quit xplr if only one context is open)
- `1`, `2`, `3`, `4` to switch to a specific context

### Install

Clone the repo into your plugin directory, see the
[doc](https://xplr.dev/en/installing-plugins).

Call the `setup` function. Optionally you can override the
defaults.

```lua
-- init.lua config
-- […]

require('ctx4').setup({
  -- you can configure your keys
  keymap = {
    next = 'tab',
    prev = 'back-tab',
    close = 'q',
    switch_to_1 = '1',
    switch_to_2 = '2',
    switch_to_3 = '3',
    switch_to_4 = "4",
  },
  title = 'ctx', -- custom panel title
  no_title = false, -- disable panel title
  -- custom styles for the context numbers, this table takes 4
  -- Style objects, one for each context
  context_styles = {{…}, {…}, {…}, {…}},
  current_style = {…}, -- custom style for the current context
  empty_style = {…}, -- custom style for the empty contexts
  reverse_current_style = true, -- reverse the current context style
})
```

Next, add it to your layout as a `Dynamic` table.\
Note that it renders as a table of one row and 9 columns.

```lua
-- Layout setup

layout_def = {
  -- […]
  { Dynamic = 'custom.ctx4.ui' }
}
```

Finally, add the following hooks:

```lua
-- init.lua config
-- […]

return {
  on_load = {
    { CallLuaSilently = 'custom.ctx4.hooks.on_load' },
  },
  on_directory_change = {
    { CallLuaSilently = 'custom.ctx4.hooks.on_pwd_change' },
  },
  on_focus_change = {
    { CallLuaSilently = 'custom.ctx4.hooks.on_focus_change' },
  },
  on_mode_switch = {},
  on_layout_switch = {},
}
```

### API

The plugin provides the following functions:

#### `get_current_context_num()`

Returns the current active context number.

#### `get_current_context_style()`

Returns the current active context style.

#### `get_contexts()`

Returns the context state object.

### Inspiration

This plugin is heavily inspired by [nnn](https://github.com/jarun/nnn) (no joke)

### License

MPL-2.0
