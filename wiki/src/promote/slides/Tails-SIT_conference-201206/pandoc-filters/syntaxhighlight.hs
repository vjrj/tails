-- A Pandoc filter to use SyntaxHighlighter for Pandoc
-- Code blocks in HTML output 
-- Matti Pastell 2011 <matti.pastell@helsinki.fi> 
-- More filters in https://bitbucket.org/mpastell/pandoc-filters/
-- Requires Pandoc 1.8

import Text.Pandoc
import Text.Pandoc.Shared
import Char(toLower)


main = interact $ jsonFilter $ bottomUp highlight

highlight :: Block -> Block
highlight (CodeBlock (_, [lang] , _ ) code) = RawBlock "html" 
          ("<pre class=\"brush: " ++ (map toLower lang) ++ "\"> \n" ++
          code ++
          "\n</pre>\n")      
highlight x = x
