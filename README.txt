====================================================================================================
rowan.nvim
====================================================================================================

Notes in plain text that still look structured, whether you use `cat`, any editor, or paste them
somewhere else.

rowan is a pure-ASCII alternative to markdown for day-to-day notes, ticket details, daily logs and
meeting notes. This repo holds the format spec and a Neovim plugin for writing it: heading
toggles, auto-aligned tables, cell navigation, links and outline pickers.

STATUS: v0.1. The format and the plugin work day to day; expect small changes.

See `spec/example.txt` for a complete example note.

== Why plain text ==================================================================================

Notes outlive the apps that write them. A `.txt` file opens in every editor, on every machine, and
will still open in thirty years. It greps, diffs cleanly in git, and pastes into a ticket, a chat
or an email without turning into markup soup.

Markdown is plain text too, but it is written to be rendered. Read raw, `#`, `##` and `###` look
almost the same, emphasis is a scatter of asterisks, and tables only line up if you align them by
hand. The structure is there, but you have to squint to see it.

The goal of rowan is notes whose structure you can see without rendering them:

- each heading level looks different at a glance, and a 100-column rule marks where it starts
- emphasis stays readable: STRONG is just uppercase
- tables are real grids that line up in any monospace font
- long URLs move out of the text into numbered references

The format is only half of it. Writing grids and padded rules by hand would be tedious, so the
plugin does it for you, and typing a rowan note in Neovim is as quick as typing markdown.

== Why Rowan =======================================================================================

Rowan is a small, hardy tree, known for growing high on exposed mountainsides where conditions are
poor. For centuries it has also been associated with protection in the folklore of northern Europe.

Rowan takes its name from that idea: something beautiful that survives in sparse conditions, and
protects what it carries.

A Rowan document is still just text. It should remain readable without the plugin, portable without
a particular editor, and understandable years after the software that created it is gone. Rowan adds
structure and beauty without taking ownership of the words underneath.

The editor may disappear. The file should survive.

== Format at a glance ==============================================================================

+------------+-----------------------------------------------------------+
| Element    | Written as                                                |
+------------+-----------------------------------------------------------+
| H1         | a line of = above and below the title                     |
| H2         | == Section ======...                                      |
| H3         | -- Topic --------...                                      |
| STRONG     | uppercase words                                           |
| soft       | ==text==                                                  |
| literal    | `text`                                                    |
| bullets    | -  then  *  then  +  by nesting level                     |
| tasks      | [ ] open,  [x] done,  [>] moved                           |
| tables     | +---+ ASCII grid, like this one                           |
| code       | ~~~ lang ... ~~~                                          |
| links      | a bare URL, or [1] with the URL defined below the section |
| note links | [[Note]], or a heading in it (see below)                  |
| callouts   | NOTE:  DECISION:  BLOCKER:                                |
| quotes     | > quoted text                                             |
| metadata   | optional key :: value lines at the top of the file        |
+------------+-----------------------------------------------------------+

A note link can point at a heading too: `[[Note|Heading]]`.

Files are `.txt` and laid out for 100 columns. The full spec is in `spec/spec.txt`.

== Install =========================================================================================

Requires Neovim 0.11 or newer. fzf-lua is optional and makes the pickers nicer.

~~~ vim
" vim-plug
Plug 'suyash-sneo/rowan.nvim'
lua require('rowan').setup({ notes_dirs = { '~/notes' } })
~~~

~~~ lua
-- lazy.nvim
{ 'suyash-sneo/rowan.nvim', opts = { notes_dirs = { '~/notes' } } }
~~~

`.txt` files under `notes_dirs` open as rowan notes. Anywhere else, run `:Rowan` to switch a buffer
on. Press `<space>?` in a note to see every key, and read `:help rowan` for the details.

== License =========================================================================================

The plugin code is licensed under GPL-3.0. If you distribute modified versions, they must stay
open source under the same license.

The format spec and everything in `spec/` are licensed under CC BY 4.0. You can build your own
tools, plugins or editors for the rowan format under any license, as long as you credit the spec.
