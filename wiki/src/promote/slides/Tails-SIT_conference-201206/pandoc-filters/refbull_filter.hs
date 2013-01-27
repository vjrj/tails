-- A Pandoc filter to turn `ref:xxx` into <span class="ref">xxx</span
-- Used to create references for HTML processed with refbull
-- Matti Pastell 2011 <matti.pastell@helsinki.fi> 
-- Requires Pandoc 1.8


import Text.Pandoc
import Text.Pandoc.Shared

main = interact $ jsonFilter $ bottomUp refs

refs :: Inline -> Inline
refs (Code attr code) 
     | (take 4 code) == "ref:" = RawInline "html" ("<span class=\"ref\">" ++ (drop 4 code) ++ "</span>")
     | otherwise = Code attr code
refs x = x
