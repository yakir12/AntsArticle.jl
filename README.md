# AntsArticle

[![Build Status](https://github.com/yakir12/AntsArticle.jl/workflows/CI/badge.svg)](https://github.com/yakir12/AntsArticle.jl/actions)
[![Build Status](https://travis-ci.com/yakir12/AntsArticle.jl.svg?branch=master)](https://travis-ci.com/yakir12/AntsArticle.jl)
[![Build Status](https://ci.appveyor.com/api/projects/status/github/yakir12/AntsArticle.jl?svg=true)](https://ci.appveyor.com/project/yakir12/AntsArticle-jl)
[![Coverage](https://codecov.io/gh/yakir12/AntsArticle.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/yakir12/AntsArticle.jl)
[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://yakir12.github.io/AntsArticle.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://yakir12.github.io/AntsArticle.jl/dev)

## How to install
If you haven't already, install [Julia](https://julialang.org/downloads/) -> you should be able to launch it (some icon on the Desktop or some such). 

1. Start Julia -> a Julia-terminal popped up
2. Copy: 
   ```julia
   import Pkg
   Pkg.Registry.add("General") # you may skip this line if this is not a fresh instalation of Julia and you've updated/added a packge before
   Pkg.Registry.add(Pkg.RegistrySpec(url = "https://github.com/yakir12/DackeLab")) # you need to do this only once for each instalation of Julia
   Pkg.add("AntsArticle") # you need to do this only once for each environment
   ```
   and paste it in the newly opened Julia-terminal, press Enter
3. You can close the Julia-terminal after it's done running

### Requirements
1. Please note, **Julia version 1.5 or newer is required**, this will not work for older versions.
2. The calibration currently requires Matlab™ with the Computer Vision Toolbox installed. 

## How to use
1. Start Julia -> a Julia-terminal popped up
2. Copy: 
   ```julia
   using AntsArticle
   savedata(path) # where `path` is the path to the directory that contains all the folders of all the experiments
   main()
   ```
   and paste it in the newly opened Julia-terminal, press Enter
3. The stats, tables, and figures have been generated in the current directory
4. You can close the Julia-terminal after it's done running

## Troubleshooting
When adding this package I got a
```
Warning: julia version requirement for package AntsArticle not satisfied
```
You'll need to update your Julia to 1.4 or higher. 

## Citing

See `CITATION.bib` for the relevant reference(s).
