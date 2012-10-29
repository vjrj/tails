-- A Pandoc filter to make beamer presentations
-- Matti Pastell 2011 <matti.pastell@helsinki.fi> 
-- Requires Pandoc 1.8

import Text.Pandoc
import Text.Pandoc.Shared


main = interact $ jsonFilter $ bottomUp beamer

beamer :: Block -> Block
beamer (Header 1 text) = RawBlock "latex" 
       (concat ["\\end{frame}\n\n"
                , "\\section{", (stringify text), "}\n"
                , "\\begin{frame}[fragile]{"
                , (stringify text), "}\n"
                , "\\tableofcontents[currentsection]\n"
                ])
beamer (Header 2 text) = RawBlock "latex" 
       (concat ["\\end{frame}\n\n"
                -- , "\\subsection{", (stringify text), "}\n"
                , "\\begin{frame}[fragile]{"
                , (stringify text), "}\n"])
beamer (Para [Image xs (u, t)]) = RawBlock "latex" ("\\centerline{\\includegraphics[width=0.8\\textheight]{" ++ u ++ "}}\n")
beamer x=x


