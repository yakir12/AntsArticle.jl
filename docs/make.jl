using AntsArticle
using Documenter

makedocs(;
    modules=[AntsArticle],
    authors="yakir12 <12.yakir@gmail.com> and contributors",
    repo="https://github.com/yakir12/AntsArticle.jl/blob/{commit}{path}#L{line}",
    sitename="AntsArticle.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://yakir12.github.io/AntsArticle.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/yakir12/AntsArticle.jl",
)
