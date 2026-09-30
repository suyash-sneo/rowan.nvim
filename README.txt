====================================================================================================
rowan.nvim
====================================================================================================

Notes in plain text that still look structured, whether you use `cat`, any editor, or paste them
somewhere else.

rowan is a pure-ASCII alternative to markdown for day-to-day notes, ticket details, daily logs and
meeting notes. In markdown, `#`, `##` and `###` look almost the same as raw text. In rowan, each
kind of structure uses characters you can tell apart at a glance. This repo holds the format spec
and a Neovim plugin for writing it: heading toggles, auto-aligned tables, cell navigation, links
and outline pickers.

STATUS: early. The format spec is drafted and the plugin is not written yet.

See `docs/example.txt` for a complete example note.

== Format at a glance ==============================================================================

~~~
H1          line of = above and below the title
H2          == Section ====================...
H3          -- Topic ----------------------...
STRONG      uppercase
soft        ==text==
literal     `text`
bullets     -  then  *  then  +   (by nesting level)
tasks       [ ]  [x]  [>]
tables      +---+ ASCII grid
code        ~~~ lang ... ~~~
links       bare URL, or [1] with the URL defined below the section
note links  [[Note]]  [[Note|Heading]]
callouts    NOTE:  DECISION:  BLOCKER:     quotes: >
metadata    optional key :: value lines at the top of the file
~~~

Files are `.txt` and laid out for 100 columns. The full spec is in `docs/spec.txt`.

== Install =========================================================================================

Not ready yet. Once the plugin exists, installing it will look like this:

~~~ vim
" vim-plug
Plug 'suyash-sneo/rowan.nvim'
~~~

~~~ lua
-- lazy.nvim
{ 'suyash-sneo/rowan.nvim', opts = { notes_dirs = { '~/notes' } } }
~~~

== Repository layout ===============================================================================

~~~
README.txt        this file, written in the rowan format
LICENSE           GPL-3.0, covers the plugin code
docs/spec.txt     the rowan format specification (CC BY 4.0, noted in its header)
docs/example.txt  an example note that uses every part of the format
~~~

== License =========================================================================================

The plugin code is licensed under GPL-3.0. If you distribute modified versions, they must stay
open source under the same license.

The format spec and everything in `docs/` are licensed under CC BY 4.0. You can build your own
tools, plugins or editors for the rowan format under any license, as long as you credit the spec.
