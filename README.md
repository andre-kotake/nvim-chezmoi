# nvim-chezmoi

A NeoVim plugin written in Lua that integrates with [chezmoi](https://www.chezmoi.io/), written entirely in Lua.

## Requirements

- Neovim
- [chezmoi](https://www.chezmoi.io/)
- [plenary.nvim](https://github.com/nvim-lua/plenary.nvim/)
- [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)

## Features

`nvim-chezmoi` provides user commands for files in the source directory that calls [chezmoi](https://www.chezmoi.io/) commands in order to:

- Detect Filetype: When opening a source file, sets the appropriate file type based on the target file name.
- Execute Template: Allows you to quickly open a new buffer with the executed template for a source file.
- List source files: Provides a [telescope](https://github.com/nvim-telescope/telescope.nvim) extension.

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
      { "nvim-telescope/telescope.nvim" },
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

Once installed, `nvim-chezmoi` will automatically call [chezmoi](https://www.chezmoi.io/) commands asynchronously whenever you open a source file.

The plugin provides the following user commands:

### Global

- `:ChezmoiListSource`: List files under the source directory.

### Source files only

- `:ChezmoiExecuteTemplate`: Opens a non-listed scratch buffer with the executed template for a opened file. Only applies for files with the ".tmpl" extension.
- `:ChezmoiDetectFileType`: Detects the correct filetype for the opened source file. Not really much use since it does it by default whenever you open a file.

## To do

- Replace target files for the source files (chezmoi edit automatically).
- Auto apply on save.
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
