# gowin-cst-mode

An Emacs major mode for editing GoWin FPGA physical constraint files (`.cst`).

## Features

- Syntax highlighting for keywords (`IO_LOC`, `IO_PORT`, etc.), attributes (`IO_TYPE`, `DRIVE`,
  etc.), values (`LVCMOS33`, `FAST`, etc.), pin locations (`M11`, `J1`), and numbers
- `//` comment support (`M-;` to toggle)
- Completion-at-point (`C-M-i`) for keywords, attributes, and values
- Imenu integration for navigating `IO_LOC`/`IO_PORT` entries
- Customizable keyword, attribute, and value lists via `M-x customize-group RET gowin-cst`

## Requirements

- Emacs 29.1 or later

## Installation

### Manual

Clone the repository and add it to your `load-path`:

```elisp
(add-to-list 'load-path "/path/to/gowin-cst-mode")
(require 'gowin-cst-mode)
```

### use-package

```elisp
(use-package gowin-cst-mode
  :load-path "/path/to/gowin-cst-mode")
```

The mode activates automatically for files with a `.cst` extension.

## License

MIT
