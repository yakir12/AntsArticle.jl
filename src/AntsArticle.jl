module AntsArticle

export main, savedata, plotquality

using Serialization, DungBase

using Format2DB, Glob, DungAnalyse

using DataStructures, CoordinateTransformations, Rotations, DataFrames, Missings, Distributions, AngleBetweenVectors, LinearAlgebra, StatsBase, OnlineStats, Colors, PrettyTables, Measurements, HypothesisTests, GLM, DelimitedFiles, Printf

using CairoMakie, MakieLayout, FileIO, AbstractPlotting
import AbstractPlotting:px
CairoMakie.activate!()


include("preparedata.jl")
include("stats.jl")
include("plot.jl")
include("quality.jl")

"""
main()
Create all the tables and figures included in the manuscript.
"""
function main()
    data = deserialize("data")
    df = getdf(data)
    speeds!(df)
    descriptive_stats(df)
    displaced_stats(df) 
    save_figures(df)
end

function goodpath(pathx)
    if isdir(pathx) && !isempty(readdir(pathx))
        x = basename(pathx)
        return !startswith(x, ['.', '_'])
    end
    return false
end

"""
savedata(path)
Convert the raw data to the standard dataset and save it.
The variable `path` is the path to the directory that
contains all the folders of all the experiments.
"""
function savedata(path)
    foreach(readdir(glob"source_*", tempdir())) do d
        rm(d, force = true, recursive = true)
    end
    todo = readdir(path, join = true)
    filter!(goodpath, todo)
    sources = Format2DB.main.(todo)
    source = DungAnalyse.joinsources(sources)
    foreach(sources) do d
        rm(d, force = true, recursive = true)
    end
    data = DungAnalyse.main(source)
    serialize("data", data)
end

"""
plotquality()
Plot some basic quality control.
"""
function plotquality()
    data = deserialize("data")
    df = getdf(data)
    plotquality(df)
end

end
