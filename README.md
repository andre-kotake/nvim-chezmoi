# nvim-chezmoi

A NeoVim plugin that integrates with [chezmoi](https://www.chezmoi.io/).

## Requirements

- Neovim
- [chezmoi](https://www.chezmoi.io/)
- [plenary](https://github.com/nvim-lua/plenary.nvim/)

## Features

`nvim-chezmoi` provides user commands for files in the source directory that calls [chezmoi](https://www.chezmoi.io/) commands asynchronously in order to:

- Detect Filetype: When opening a source file, sets the appropriate file type based on the target file name.
- Execute Template: Allows you to quickly open a new buffer with the executed template for a source file.

## Installation

First, ensure that [chezmoi is in your PATH](https://www.chezmoi.io/install/).

Then, install `nvim-chezmoi` with your favorite plugin manager. You'll need [plenary](https://github.com/nvim-lua/plenary.nvim/) installed too.

If you are lazy-loading, disable it for `nvim-chezmoi` and ensure [plenary](https://github.com/nvim-lua/plenary.nvim/) is loaded first.

### With `lazy.nvim`

```lua
  return {
    "andre-kotake/nvim-chezmoi",
    lazy = false, -- nvim-chezmoi can't be lazy loaded.
    dependencies = {
      -- nvim-chezmoi depends on plenary.nvim.
      { "nvim-lua/plenary.nvim" }
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
    -- Default source path for your dotfiles.
    source_path = "$HOME/.local/share/chezmoi",
  }
```

## Usage

Once installed, `nvim-chezmoi` will automatically call [chezmoi](https://www.chezmoi.io/) commands asynchronously whenever you open a source file.

You can change the default source path if your dotfiles source is in a different path.

The plugin provides the following user commands only for files inside the source:

- `:ChezmoiDetectFileType`: Detects the correct filetype for the opened source file. Not really much use since it does it by default whenever you open a file.
- `:ChezmoiExecuteTemplate`: Opens a non-listed scratch buffer with the executed template for a opened file. Only applies for files with the ".tmpl" extension.

## Why

I just wanted to try my hand at writing a Neovim plugin since it is slowly becoming my main editor. There are also alternatives listed below which inspired me.

## Acknowledgements

- [chezmoi](https://www.chezmoi.io/)
- [plenary](https://github.com/nvim-lua/plenary.nvim/)
- [alker0/chezmoi.vim](https://github.com/alker0/chezmoi.vim)
- [xvzc/chezmoi.nvim](https://github.com/xvzc/chezmoi.nvim)


## Contributing

All contributions and suggestions are welcome; Feel free to open a issue or pull request.

## License

MIT
