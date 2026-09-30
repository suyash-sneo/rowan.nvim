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

== Why rowan =======================================================================================

The rowan, or mountain ash, is a small, hardy tree that grows where little else will, on
mountainsides and in thin soil, and carries bright red berries into winter.

In Celtic and northern European folklore it is a tree of protection. Rowan twigs were hung over
doors and byres, and crosses of rowan tied with red thread were worn to keep enchantment away, as an
old Scottish rhyme has it: "rowan tree and red thread hold the witches all in dread". In the Norse
myths, Thor was nearly swept away while wading the river Vimur and saved himself by catching hold of
a rowan on the bank.

That is the spirit of this project: a small, sturdy format that keeps your notes safe from lock-in
and legible wherever they end up.

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
