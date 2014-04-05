-- A Pandoc filter I use for my website mpastell.com
-- Dos the following
-- * Use Pygments for Pandoc Code blocks in HTML output 
-- * Disable pandoc figures and always use the inline img style
-- Matti Pastell 2011 <matti.pastell@helsinki.fi> 
-- More filters in https://bitbucket.org/mpastell/pandoc-filters/
-- Requires Pandoc 1.8

import Text.Pandoc
import Text.Pandoc.Shared
import Char(toLower)
import System.Process (readProcess)
import System.IO.Unsafe


main = interact $ jsonFilter $ bottomUp mpastell

mpastell :: Block -> Block
mpastell (CodeBlock (_, options , _ ) code) = RawBlock "html" (pygments code options)
mpastell (Para [Image xs (u, t)]) = RawBlock "html"
          (concat [
          "<p><img src=\"", u, "\" title=\"", t ,"\" alt=\"", (stringify xs), "\"/></p>"])
mpastell x = x

pygments:: String -> [String] -> String
pygments code options 
         | (length options) == 1 = unsafePerformIO $ readProcess "pygmentize" ["-l", (map toLower (head options)),  "-f", "html"] code       
         | (length options) == 2 = unsafePerformIO $ readProcess "pygmentize" ["-l", (map toLower (head options)), "-O linenos=inline",  "-f", "html"] code
         | otherwise = "<div class =\"highlight\"><pre>" ++ code ++ "</pre></div>"

