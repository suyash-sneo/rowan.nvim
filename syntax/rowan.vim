if exists('b:current_syntax')
  finish
endif

" Headings
" nextgroup instead of a lookbehind: far faster, and the title wins over inline groups.
syntax match rowanH1Rule /^===\+$/ nextgroup=rowanH1 skipnl
syntax match rowanH1 /^\%(===\+$\)\@!.*\S.*\ze\n===\+$/ contained
syntax match rowanH2 /^== .*\S ===\+$/
syntax match rowanH3 /^-- .*\S ---\+$/
syntax match rowanDivider /^---\+$/

" Key-value block: only at the very top of the file, ends at the first blank line or heading.
syntax region rowanKv start=/\%1l\ze\S.*::/ end=/^$/ end=/^\ze\%(===\+$\|== \|-- \)/ contains=rowanKvKey,rowanKvSep,rowanUrl
syntax match rowanKvKey /^\S.\{-}\ze\s*::/ contained
syntax match rowanKvSep /::/ contained

" STRONG is plain uppercase, so emphasis can't be told apart from acronyms exactly.
" Heuristic: a run of 2+ all-caps words (DO NOT MERGE), or one all-caps word of 4+ letters
" (BLOCKED). Short acronyms like API or PR stay plain, and ticket IDs like AUTH-112 are skipped.
syntax match rowanStrong /\<\u\{2,}\>\%(-\d\)\@!\%(\s\+\u\{2,}\>\%(-\d\)\@!\)\+\|\<\u\{4,}\>\%(-\d\)\@!/

" Inline
syntax region rowanSoft matchgroup=rowanMarker start=/==\ze[^= \t]/ end=/[^= \t]\zs==/ oneline
syntax match rowanLiteral /`[^`]\+`/
syntax match rowanUrl /\<https\?:\/\/\S*[^[:space:].,;:)]/
syntax match rowanRef /\[\d\+\]/
syntax region rowanLink matchgroup=rowanMarker start=/\[\[/ end=/\]\]/ oneline

" Lists and tasks
syntax match rowanBullet /^\s*\zs[-*+]\ze\s/
syntax match rowanTaskOpen /^\s*\zs\[ \]/
syntax match rowanTaskDone /^\s*\[x\].*$/
syntax match rowanTaskMoved /^\s*\[>\].*$/

" Tables
syntax match rowanTableBorder /^+[-+]*+$/
syntax match rowanTablePipe /^|\||$\|\s\zs|\ze\s/

" Callouts and quotes
syntax match rowanNote /^NOTE:/
syntax match rowanDecision /^DECISION:/
syntax match rowanBlocker /^BLOCKER:/
syntax match rowanQuote /^>.*$/

" Code blocks come last so nothing else matches inside them.
syntax region rowanCode matchgroup=rowanCodeFence start=/^\~\~\~.*$/ end=/^\~\~\~$/ keepend

highlight default link rowanH1Rule rowanH1
highlight default link rowanDivider Comment
highlight default link rowanKvKey @property
highlight default link rowanKvSep Comment
highlight default link rowanStrong @markup.strong
highlight default link rowanSoft @markup.italic
highlight default link rowanMarker Comment
highlight default link rowanLiteral @markup.raw
highlight default link rowanUrl @markup.link.url
highlight default link rowanRef Underlined
highlight default link rowanLink Underlined
highlight default link rowanBullet @markup.list
highlight default link rowanTaskOpen @markup.list.unchecked
highlight default link rowanTaskDone Comment
highlight default link rowanTableBorder Comment
highlight default link rowanTablePipe Comment
highlight default link rowanNote DiagnosticInfo
highlight default link rowanDecision DiagnosticOk
highlight default link rowanBlocker DiagnosticError
highlight default link rowanQuote @markup.quote
highlight default link rowanCode @markup.raw.block
highlight default link rowanCodeFence Comment

let b:current_syntax = 'rowan'
