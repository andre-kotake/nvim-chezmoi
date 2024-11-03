# nvim-chezmoi

A NeoVim plugin written in Lua that integrates with [chezmoi](https://www.chezmoi.io/).

## Requirements

- Neovim
- [chezmoi](https://www.chezmoi.io/)
- [plenary.nvim](https://github.com/nvim-lua/plenary.nvim/)
- [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)

## Features

- Interface for chezmoi commands.
- Sets the appropriate filetype for a source file based on the target file name.
- Quickly open a new buffer with the executed template for a source file.
- Two [telescope](https://github.com/nvim-telescope/telescope.nvim) extensions.

## Installation

First, ensure that [chezmoi is in your PATH](https://www.chezmoi.io/install/).

Then, install `nvim-chezmoi` with your favorite plugin manager. You'll need both [plenary](https://github.com/nvim-lua/plenary.nvim/) and [telescope](https://github.com/nvim-telescope/telescope.nvim) installed too.

If you are lazy-loading, disable it for `nvim-chezmoi`.

### With `lazy.nvim`

```lua
  return {
    "andre-kotake/nvim-chezmoi",
    lazy = false,
    dependencies = {
      { "nvim-lua/plenary.nvim" },
    },
    opts = {},
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
    -- Default chezmoi source path.
    -- Change this only if your dotfiles live in a different directory.
    source_path = "$HOME/.local/share/chezmoi",
  }
```

## Usage

### User Commands

#### Global

- `:ChezmoiEdit [file...]`: Opens the source file from current buffer target file. Encrypted files are not supported yet. You may specify optional `[file]` argument if you want to open that instead. Example: `:ChezmoiEdit ~/.bashrc`
- `:ChezmoiManaged`: List source managed files with [telescope](https://github.com/nvim-telescope/telescope.nvim).

#### Source files only

- `:ChezmoiExecuteTemplate`: Preview the executed template in a new buffer. Only applies for files with the ".tmpl" extension.
- `:ChezmoiDetectFileType`: Detects the correct filetype for the opened source file. Not really much use since it does it by default whenever you open a file.

### Autocmds

#### Source files only

- `NvimChezmoi_SourcePath`: Executes `:ChezmoiDetectFileType` for the currently opened file and also provides the user command `:ChezmoiExecuteTemplate`.

### Telescope Extension
- `:Telescope nvim-chezmoi managed`: Same as `:ChezmoiManaged` user command.
- `:Telescope nvim-chezmoi special_files`: Lists all chezmoi special files under source path.

## API

You may use `nvim-chezmoi.chezmoi.exec` function in order to execute commands and provide custom functionality.

```lua
  local chezmoi = require("nvim-chezmoi.chezmoi")
  local result = chezmoi.exec("managed", {
    "--path-style relative "
  })
  vim.print(vim.inspect(result))
```

The parameters for `exec` are:

  - `cmd (string)`: Command to execute, e.g. "source-path"
  - `args (string[]|nil)`: Additional args to append to `cmd`, e.g. ".bashrc"
  - `stdin? (string[]|nil)`: Stdin if needed for command.
  - `success_only? (boolean)`: Only returns from cache if result was successful.
  - `force? (boolean)`: Force execution ignoring cache.

Returns a `ChezmoiCommandResult` table with the fields:

  - `success (boolean)`: `true` if command returned status code 0.
  - `data (table)`: The result data from command execution or error messages if `success` is `false`.

## To do

- Handle encrypted files.
- Auto apply on save/quit.
- Refactor Telescope extension.

## Acknowledgements

Stuff that helped me or inspired this:

- [chezmoi](https://www.chezmoi.io/)
- [plenary](https://github.com/nvim-lua/plenary.nvim/)
- [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)

For cool alternatives:

- [alker0/chezmoi.vim](https://github.com/alker0/chezmoi.vim)
- [xvzc/chezmoi.nvim](https://github.com/xvzc/chezmoi.nvim)


## Contributing

All contributions and suggestions are welcome; Feel free to open an issue or pull request.

## License

MIT
