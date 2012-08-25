-- My way of using labels for latex tables with pandoc
-- Transforms Pandocs caption "Some text {label}" 
-- (which becomes \caption{Some text \{mylabel\}} in Latex)
-- into 
-- \label{mylabel}
-- \caption{Some text}
-- NOTE: this is not a pandoc filter, but tranforms the generated
-- Latex document
-- Matti Pastell 2011 <matti.pastell@helsinki.fi> 

import Text.Regex

main = interact (unlines . map makelabel . lines)

-- Check if the line has caption
makelabel :: String -> String
makelabel x
        | (length (splitRegex (mkRegex "\\caption") x)) <= 1 = x
        | otherwise = getlabel x

-- If the line has a caption with a label return the label + caption
-- The ugly regex matches \{ or \}
getlabel :: String -> String
getlabel x 
         | ((length y) == 1) = x
         | otherwise = (trim (y !! 0)) ++ (y !! 2) ++  "\n\\label{" ++ (y !! 1) ++ "}"
         where y = (splitRegex (mkRegex "\\\\\\{|\\\\\\}") x)

-- Trim extra whitespace from the caption
trim :: String -> String
trim = unwords . words

