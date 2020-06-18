############# data preparation ###################

function intended(d::AbstractString)
    m = match(r"\((.+),(.+)\)", d)
    x, y = parse.(Int, m.captures)
    DungBase.Point(x, y)
end


function parsetitle(title, r)
    run = r.data
    return (nest = run.nest, 
            feeder = run.feeder, 
            fictive_nest = run.fictive_nest, 
            track = run.track, 
            dropoff = run.dropoff,
            pickup = run.pickup,
            title = title,
            comment = r.metadata.comment,
            nest2feeder = get(r.metadata.setup, :nest2feeder, missing),
            experience = get(r.metadata.setup, :experience, missing),
            pickup_loc = get(r.metadata.setup, :pickup, missing),
            dropoff_loc = get(r.metadata.setup, :dropoff, missing),
            displacement = passmissing(intended)(get(r.metadata.setup, :displacement, missing)))
end

function getdf(data)
    df = DataFrame(parsetitle(k, r) for (k, v) in data for r in v.runs)

    # @. df[!, :displace_direction] = switchdirections(df.displace_direction)
    @. df[!, :group] = getgroup(df.pickup_loc, df.displacement, df.dropoff_loc)
    # @. df[!, :set] = getset(df.transfer, df.group)

    categorical!(df, [:experience, :pickup_loc, :dropoff_loc])
    # levels!(df.group, ["none", "left", "right", "away", "towards", "zero", "back", "far"])

    # df[!, :direction_deviation]  = [angle(r.fictive_nest - r.feeder, turningpoint(r.track) - r.feeder) for r in eachrow(df)]
    # max_direction_deviation = maximum(r.direction_deviation for r in eachrow(df) if r.group ∉ ("far", "zero"))
    # mean_direction_deviation = mean(r.direction_deviation for r in eachrow(df) if r.group ∉ ("far", "zero"))
    # filter!(r -> r.group ≠ "far" || r.direction_deviation < 4mean_direction_deviation, df)

    df[!, :turning_point] .= zero.(df.feeder)
    df[!, :center_of_search] .= zero.(df.feeder)
    for r in eachrow(df)
        trans = createtrans(r.nest, r.dropoff, r.fictive_nest)
        @. r.track.coords = trans(r.track.coords)
        @. r.track.rawcoords.xy .= trans(r.track.rawcoords.xy)
        r.feeder = trans(r.feeder)
        r.fictive_nest = trans(r.fictive_nest)
        r.nest = trans(r.nest)
        r.pickup = trans(r.pickup)
        r.dropoff = trans(r.dropoff)
        Δ = r.displacement - r.fictive_nest
        # r.turning_point = turningpoint(r.track) + Δ
        # r.center_of_search = searchcenter(r.track) + Δ
    end

    groups = levels(df.group)
    nc = length(groups)
    colors = OrderedDict(zip(groups, [colorant"black"; distinguishable_colors(nc - 1, [colorant"white", colorant"black"], dropseed = true)]))

    gdf = groupby(df, :group)
    DataFrames.transform!(gdf, :group => (g -> colors[g[1]]) => :groupcolor)
    DataFrames.transform!(gdf, :groupcolor => getcolor => :color)

    df
end

__x(x) = x == 0 ? "" :
         x < 0 ? "left" :
         "right"
__y(y) = y == 0 ? "" :
         y < 0 ? "away" :
         "towards"
function _f(x, y) 
    x = __x(x)
    y = __y(y)
    join(filter(!isempty, [x, y]), " ")
end
_f(xy) = _f(xy...)
_f(::Missing) = ""
getgroup(pickup, displacement, dropoff) = string(pickup, " ", _f(displacement), " ", dropoff)

#=switchdirections(_::Missing) = missing
switchdirections(d) =   d == "left" ? "right" :
                        d == "right" ? "left" :
                        d=#

# getgroup(displace_location::Missing, transfer, displace_direction) = transfer
# getgroup(displace_location, transfer, displace_direction) = displace_location == "nest" ? "zero" : displace_direction
# getset(_::Missing, d) = d == "none" ? "Closed" : "Displacement"
# getset(_, __) = "Transfer"


# intended(::Missing) = missing
# intended(d) = intended(string(d))

_get_center(nest::Missing, fictive_nest) = fictive_nest
_get_center(nest, fictive_nest) = nest
function createtrans(nest, dropoff, fictive_nest)
    v = dropoff - fictive_nest
    α = atan(v[2], v[1])
    rot = LinearMap(Angle2d(-π/2 - α))
    trans = Translation(-_get_center(nest, fictive_nest))
    passmissing(rot ∘ trans)
end


function highlight(c, i, n)
    h = HSL(c)
    HSL(h.h, h.s, i/(n + 1))
end
function getcolor(g)
    n = length(g)
    [highlight(c, i, n) for (i, c) in enumerate(g)]
end


