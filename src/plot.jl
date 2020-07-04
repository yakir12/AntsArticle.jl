######################## common traits for the plots 

max_width = 493.228346
markers = Dict("turning_point" => '•', "center_of_search" => '■')
brighten(c, p = 0.5) = weighted_color_mean(p, c, colorant"white")
mydecompose(origin, radii) = [origin + radii .* Iterators.reverse(sincos(t)) for t in range(0, stop = 2π, length = 51)]
mydecompose(x) = mydecompose(x.origin, x.radii)
legendmarkers = OrderedDict(
                            "track" => (linestyle = nothing, linewidth = 0.3, color = :black),
                            "burrow" => (color = :black, marker = '⋆', strokecolor = :black, markerstrokewidth = 0.5, strokewidth = 0.5, markersize = 15px),
                            "fictive burrow" => (color = :white, marker = '⋆', strokecolor = :black, markerstrokewidth = 0.5, strokewidth = 0.5, markersize = 15px),
                            "dropoff" => (color = :black, marker = '↓', strokecolor = :white, markerstrokewidth = 0.5, strokewidth = 0.1, markersize = 15px),
                            "turning point" => (color = :black, marker = markers["turning_point"], strokecolor = :transparent, markersize = 15px),
                            "center of search" => (color = :black, marker = markers["center_of_search"], strokecolor = :transparent, markersize = 5px),
                            "mean ± FWHM" => [(color = brighten(colorant"black", 0.75), strokecolor = :transparent, polypoints = mydecompose(Point2f0(0.5, 0.5), Vec2f0(0.75, 0.5))),
                                           (color = :white, marker = '+', strokecolor = :transparent, markersize = 10px), 
                                          ])
function getellipse(xy)
    n = length(xy)
    X = Array{Float64}(undef, 2, n)
    for i in 1:n
        X[:,i] = xy[i]
    end
    dis = fit(DiagNormal, X)
    radii = sqrt(2log(2))*sqrt.(var(dis)) # half the FWHM
    (origin = Point2f0(mean(dis)), radii = Vec2f0(radii))
end
function distance2nest(track)
    length(searching(track)) < 10 && return Inf
    t = homing(track)
    i = findfirst(>(0) ∘ last, t)
    isnothing(i) ? Inf : abs(first(t[i]))
end
apply_element(xs) = apply_element.(xs)
apply_element(x::NamedTuple) =  :marker ∈ keys(x) ? MarkerElement(; x...) :
                                :linestyle ∈ keys(x) ? LineElement(; x...) :
                                PolyElement(; x...)

label!(scene, ax, letter) = LText(scene, letter, fontsize = 12, padding = (10, 0, 0, 10), halign = :left, valign = :top, bbox = lift(FRect2D, ax.scene.px_area), font ="Noto Sans Bold")
plottracks!(ax, g::GroupedDataFrame) = plottracks!.(Ref(ax), g)
plottracks!(ax, g::Union{SubDataFrame, DataFrame}) = plottracks!.(Ref(ax), eachrow(g))
plottracks!(ax, r::DataFrameRow) = lines!(ax, r.track.coords; legendmarkers["track"]..., color = r.color)
function plotpoints!(ax, g, point_type)
    if !ismissing(g[1].nest[1])
        scatter!(ax, [zero(Point2f0)]; legendmarkers["burrow"]...)
    end
    for (k, gg) in pairs(g)
        xy = gg[!, point_type]
        ellipse = getellipse(xy)
        c = gg.groupcolor[1]
        poly!(ax, mydecompose(ellipse), color = RGBA(brighten(c, 0.5), 0.5))
        scatter!(ax, [ellipse.origin]; legendmarkers["mean ± FWHM"][2]...)
        scatter!(ax, xy; legendmarkers[replace(point_type, "_" => " ")]..., color = RGBA(c, 0.75))
        # scatter!(ax, gg.fictive_nest; legendmarkers["fictive burrow"]..., strokecolor = gg.groupcolor[1])
        scatter!(ax, gg.dropoff; legendmarkers["dropoff"]..., color = gg.groupcolor[1])
        scatter!(ax, [gg.intended_fictive_nest[1]]; legendmarkers["fictive burrow"]..., strokecolor = gg.groupcolor[1])
    end
end

######################## Figure 5 ################

function binit(track, h, nbins, m, M)
    o = Union{Variance, Missing}[Variance() for _ in 1:nbins]
    d = track.rawcoords
    # to = track.tp
    to = findfirst(x -> x.xy[2] > 0, d)
    to = isnothing(to) ? length(d) : to
    for (p1, p2) in Iterators.take(zip(d, lag(d, -1, default = d[to])), to)
        y = -(p2.xy[2] + p1.xy[2])/2
        if m < y < M && p1.t ≠ p2.t
            i = StatsBase.binindex(h, y)
            v = norm(p2.xy - p1.xy)/(p2.t - p1.t)
            fit!(o[i], v)
        end
    end
    replace!(x -> nobs(x) < 2 ? missing : x, o)
end


function plotspeed(df)

set_theme!(
#    font = "Helvetica", # 
    fontsize = 10,
    resolution = (max_width, 500.0),
    linewidth = 0.3,
    strokewidth = 1px, 
    markersize = 3px, 
    rowgap = Fixed(10), 
    colgap = Fixed(10),
    LLegend = (markersize = 10px, markerstrokewidth = 1, patchsize = (10, 10), rowgap = Fixed(2), titlegap = Fixed(5), groupgap = Fixed(10), titlehalign = :left, gridshalign = :left, framecolor = :transparent, padding = 0, linewidth = 0.3), 
    LAxis = (xticklabelsize = 8, yticklabelsize = 8, xlabel = "X (cm)", ylabel = "Y (cm)", autolimitaspect = 1, xtickalign = 1, xticksize = 3, ytickalign = 1, yticksize = 3, xticklabelpad = 4)
)
    
    data = deserialize("/home/yakir/tmp/data")
    df = getdf(data)
    d = filter(r -> r.pickup_loc == "feeder" && r.dropoff_loc ≠ "medium" && r.nest2feeder == 130 && r.experience == "experienced", df)
    gdf = groupby(d, :speedgroups)

    #=scene, layout = layoutscene()
    ax = layout[1,1] = LAxis(scene, aspect = DataAspect())
    r = gd[3,:]
    lines!(ax, r.track.coords)
    lines!(ax, r.track.rawcoords.xy, color = :red)
    scatter!(ax, [turningpoint(r.track)], markersize = 5px)
    scatter!(ax, [r.feeder], markersize = 10px, color = :red)
    scatter!(ax, [r.dropoff], markersize = 10px, marker = '↓')
    scatter!(ax, [r.pickup], markersize = 10px, marker = '↑')
    FileIO.save("a.pdf", scene)=#

    m, M = (0, 120)
    nbins = 6
    bins = range(m, stop = M, length = nbins + 1)
    mbins = StatsBase.midpoints(bins)
    h = StatsBase.Histogram(bins)
    scene, layout = layoutscene(10, resolution = (max_width, 200.0))
    axs = [LAxis(scene, 
                 aspect = nothing, 
                 autolimitaspect = nothing,
                 # xlabel = "Distance to burrow (cm)",
                 ylabel = "Speed (cm/s)",
                 xticks = mbins,
                 xreversed = true
                ) for _ in 1:2]
    for (i, _g) in enumerate(gdf)
        # _g = first(gdf)
        g = DataFrame(_g, copycols = false)
        g[!, :id] .= 1:nrow(g)
        DataFrames.transform!(g, :id, :track => ByRow(x -> binit(x, h, nbins, m, M)) => :yv)
        μ = allowmissing([Variance() for _ in 1:nbins])
        foreach(i -> reduce(fit!, skipmissing(passmissing(mean)(yv_row[i]) for yv_row in g.yv), init = μ[i]), 1:nbins)
        replace!(x -> nobs(x) < 2 ? missing : x, μ)
        bandcolor = RGB(only(distinguishable_colors(1, [colorant"white"; g.color;], dropseed = true))) #:yellow
        x = [x for (x,y) in zip(mbins, μ) if !ismissing(y)]
        mu = mean.(skipmissing(μ))
        σ = std.(skipmissing(μ))
        bh = band!(axs[i], x, mu .- σ, mu .+ σ, color = RGBA(bandcolor, 0.25))
        lh = lines!(axs[i], x, mu, color = :white, linewidth = 5)
        for r in eachrow(g)
            xy = [Point2f0(x, mean(y)) for (x,y) in zip(mbins, r.yv) if !ismissing(y)]
            lines!(axs[i], xy; legendmarkers["track"]..., color = r.color)
            scatter!(axs[i], xy; legendmarkers["turning point"]..., color = r.color)
        end
        axs[i].title = g.speedgroups[1]
    end
    layout[1, 1:2] = axs
    layout[2, 1:2] = LText(scene, "Distance to burrow (cm)")
    linkyaxes!(axs...)
    ylims!(axs[1], 0, 35)
    xlims!.(axs, Iterators.reverse(extrema(mbins))...)
    hideydecorations!(axs[2], grid = false)
    hidexdecorations!.(axs, grid = false, ticklabels = false, ticks = false)
    FileIO.save("speed.pdf", scene)

end


function getname(k) 
    if length(k) > 1
        k1 = k[1]
        k = [merge(k1, (displace_direction = replace(k1.displace_direction, r"(left|right)" => "left and right"), ))]
    end
    join(values(only(k)), " ") 
end

function plotfigures(df)

set_theme!(
#    font = "Helvetica", # 
    fontsize = 10,
    resolution = (max_width, 500.0),
    linewidth = 0.3,
    strokewidth = 1px, 
    markersize = 3px, 
    rowgap = Fixed(10), 
    colgap = Fixed(10),
    LLegend = (markersize = 10px, markerstrokewidth = 1, patchsize = (10, 10), rowgap = Fixed(2), titlegap = Fixed(5), groupgap = Fixed(10), titlehalign = :left, gridshalign = :left, framecolor = :transparent, padding = 0, linewidth = 0.3), 
    LAxis = (xticklabelsize = 8, yticklabelsize = 8, xlabel = "X (cm)", ylabel = "Y (cm)", autolimitaspect = 1, xtickalign = 1, xticksize = 3, ytickalign = 1, yticksize = 3, xticklabelpad = 4)
)

    gdf = groupby(df, [:displace_direction, :nest2feeder, :experience, :dropoff_loc, :pickup_loc])

    ks = NamedTuple.(keys(gdf))
    y = Vector{Vector{eltype(ks)}}(undef, 0)
    for k in ks
        m = match(r"(left|right)", k.displace_direction)
        if !isnothing(m)
            cur = only(m.captures)
            alt = cur == "left" ? "right" : "left"
            other = merge(k, (displace_direction = replace(k.displace_direction, cur => alt),))
            i = findfirst(isequal(other), ks)
            if !isnothing(i)
                push!(y, [k, other])
                deleteat!(ks, i)
                continue
            end
        end
        push!(y, [k])
    end


    for k in y
        scene, layout = layoutscene()#0, resolution = (max_width, 600.0))
        ax = layout[1,1] = LAxis(scene)
        for g in gdf[k]
            plottracks!(ax, g)
        end
        name = string("tracks ", getname(k))
        FileIO.save("$name.pdf", scene)
    end


    x = copy(legendmarkers);
    delete!(x, "dropoff")
    polys = OrderedDict(string(k.displace_direction) => (color = v.groupcolor[1], strokecolor = :transparent) for (k, v) in pairs(gdf))
    for k in y
        scene, layout = layoutscene(0, resolution = (max_width, 200.0))
        axs = layout[1,1:2] = [LAxis(scene, autolimitaspect = 1) for _ in 1:2]
        for (i, point_type) in enumerate(("turning_point", "center_of_search"))
            plotpoints!(axs[i], gdf[k], point_type)
            axs[i].title = point_type
        end
        linkaxes!(axs...)
        autolimits!.(axs)
        hideydecorations!(axs[2], grid = false)
        hidexdecorations!.(axs, grid = false, ticklabels = false, ticks = false)
        layout[2, 1:2] = LText(scene, "X (cm)")
        layout[3, 1:2] = LLegend(scene, apply_element.(values.([polys, x])), collect.(keys.([polys, x])), ["Direction of displacements", " "], orientation = :horizontal, nbanks = 3, tellheight = true, height = Auto(), groupgap = 30);
        name = string("tps ", getname(k))
        FileIO.save("$name.pdf", scene)
    end
end
