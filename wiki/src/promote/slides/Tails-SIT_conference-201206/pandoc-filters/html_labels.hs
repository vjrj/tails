-- My way of using ID for HTML tables with pandoc
-- Transforms Pandocs caption "Some text {label}" 
-- (which becomes <caption>Some text {mylabel}</caption> in HTML)
-- into 
-- <caption id="mylabel">Some text</caption>
-- NOTE: this is not a pandoc filter, but tranforms the generated
-- HTML document
-- Matti Pastell 2011 <matti.pastell@helsinki.fi> 

import Text.Regex
import Data.String.Utils

main = interact (unlines . map makelabel . lines)

-- Check if the line has caption
makelabel :: String -> String
makelabel x
        | (length (splitRegex (mkRegex "<caption>") x)) <= 1 = x
        | otherwise = getlabel x

-- If the line has a caption with a label return the label + caption
-- The ugly regex matches \{ or \}
getlabel :: String -> String
getlabel x 
         | ((length y) == 1) = x
         | otherwise = (addid (y !! 0) (y !! 1)) ++ (y !! 2)
         where y = (splitRegex (mkRegex "\\{|\\}") x)

-- Trim extra whitespace from the caption
addid :: String -> String -> String
addid caption id = replace ">" (" id=\"" ++ id ++ "\">") caption 

