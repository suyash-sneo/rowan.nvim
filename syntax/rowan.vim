if exists('b:current_syntax')
  finish
endif

syntax match rowanH1Rule /^===\+$/
syntax match rowanH1 /\%(^===\+\n\)\@<=.*\S.*\ze\n===\+$/
syntax match rowanH2 /^== .*\S ===\+$/
syntax match rowanH3 /^-- .*\S ---\+$/
syntax match rowanDivider /^---\+$/

highlight default link rowanH1Rule rowanH1
highlight default link rowanDivider NonText

let b:current_syntax = 'rowan'
