# nvim-chezmoi

A NeoVim plugin written in Lua that integrates with [chezmoi](https://www.chezmoi.io/).

## Requirements

- Neovim 0.10+ (uses `vim.system`)
- [chezmoi](https://www.chezmoi.io/)
- [snacks.nvim](https://github.com/folke/snacks.nvim)

## Features

- Interface for chezmoi commands.
- Sets the appropriate filetype for a source file based on the target file name.
- Preview the executed template in a new window.
- Apply all files or specified ones.
- Picker integration (via [snacks.nvim](https://github.com/folke/snacks.nvim)) for browsing managed and special chezmoi files.

## Migration

> [!WARNING] 
> **Breaking changes on "main":** The "main" branch introduces changes that are not backward-compatible with version "1.0.0". 
> If you need the legacy implementation (with Telescope and Plenary), use the [Version 1.0.0](https://github.com/andre-kotake/nvim-chezmoi/tree/1.0.0).

## Installation

[New v2 announcement!](https://github.com/andre-kotake/nvim-chezmoi/discussions/29)

First, ensure that [chezmoi is in your PATH](https://www.chezmoi.io/install/).

Then, install `nvim-chezmoi` with your favorite plugin manager. You'll need [snacks.nvim](https://github.com/folke/snacks.nvim) installed too.

### With `lazy.nvim`

```lua
  return {
    "andre-kotake/nvim-chezmoi",
    dependencies = {
      { "folke/snacks.nvim" },
    },
    opts = {
      -- Your custom config
    },
    config = function(_, opts)
      require("nvim-chezmoi").setup(opts)
    end,
  }
```

## Configuration

Default configuration values for `nvim-chezmoi`:

```lua
  {
    -- Show extra debug messages.
    debug = false,
    -- chezmoi source path. Defaults to the result of `chezmoi source-path`
    -- Change this only if your dotfiles live in a different directory.
    source_path = nil,
    edit = {
      -- Automatically apply file on save. Can be one of: "auto", "confirm" or "never"
      apply_on_save = "never",
    },
    window = {
      -- Changes the layout for executed template window.
      execute_template = {
        relative = "editor",
        width = vim.o.columns,
        height = vim.o.lines,
        row = 0,
        col = 0,
        style = "minimal",
        border = "single",
      },
    },
  }
```

## Usage

### User Commands

#### Global

- `:ChezmoiApply [file...]`: Applies changes to source files. You may specify optional `file` args to apply them only.
- `:ChezmoiEdit [file...]`: Opens the source file from current buffer target file.You may specify optional `[file]` argument if you want to open that instead. Example: `:ChezmoiEdit ~/.bashrc`
  Encrypted files have partial supported. Tested and working fine for gpg encryption as long as you have `args: ["--quiet"]` in your [chezmoi](https://www.chezmoi.io/) configuration.
- `:ChezmoiManaged`: List source managed files via Snacks.picker. Shows a diff preview of pending changes for each file.
- `:ChezmoiFiles`: List special chezmoi files (`.chezmoi*`) in the source directory via Snacks.picker.

#### Source files only

- `:ChezmoiExecuteTemplate`: Preview the executed template in a new buffer. Only applies for files with the ".tmpl" extension.
- `:ChezmoiDetectFileType`: Detects the correct filetype for the opened source file. Not really much use since it does it by default whenever you open a file.

## To do

- Implement async-variants of all command modules

## Acknowledgements

Stuff that helped me or inspired this:

- [chezmoi](https://www.chezmoi.io/)
- [plenary](https://github.com/nvim-lua/plenary.nvim/)
- [snacks.nvim](https://github.com/folke/snacks.nvim)

For cool alternatives:

- [alker0/chezmoi.vim](https://github.com/alker0/chezmoi.vim)
- [xvzc/chezmoi.nvim](https://github.com/xvzc/chezmoi.nvim)

## Contributors

A huge thanks to:

- [103sbavert](https://github.com/103sbavert) for the bug fixes and improvements to this project.

## Contributing

All contributions and suggestions are welcome; Feel free to open an issue or pull request.

## License

MIT

Test
