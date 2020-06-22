function plotquality(df)
    legendmarkers["feeder"] = (color = :black, marker = '▴', strokecolor = :black, markerstrokewidth = 0.5, strokewidth = 0.5, markersize = 15px)
    legendmarkers["pickup"] = (color = :black, marker = '↑', strokecolor = :black, markerstrokewidth = 0.5, strokewidth = 0.5, markersize = 15px)
    legendmarkers["dropoff"] = (color = :black, marker = '↓', strokecolor = :black, markerstrokewidth = 0.5, strokewidth = 0.5, markersize = 15px)
    delete!(legendmarkers, "mean ± FWHM")
    delete!(legendmarkers, "center of search")
    polys = OrderedDict(string(df.group[1]) => (color = df.groupcolor[1], strokecolor = :transparent))
    for r in eachrow(df)
        c = r.groupcolor
        scene, layout = layoutscene()#0, resolution = (2max_width, 900.0))
        ax = layout[1,1] = LAxis(scene, aspect = DataAspect())
        scatter!(ax, r.track.rawcoords.xy, color = RGBA(1,0,0,0.5), markersize = 5px)#; legendmarkers["track"]..., color = :red)
        lines!(ax, homing(r.track); legendmarkers["track"]..., color = :blue)
        lines!(ax, searching(r.track); legendmarkers["track"]..., color = c)
        scatter!(ax, [turningpoint(r.track)]; legendmarkers["turning point"]..., color = RGBA(c, 0.75))
        # scatter!(ax, [searchcenter(r.track)]; legendmarkers["center of search"]..., color = RGBA(c, 0.75))
        # if !ismissing(r.feeder)
        scatter!(ax, [r.feeder]; legendmarkers["feeder"]..., color = RGBA(c, 0.75))
        # end
        if !ismissing(r.nest)
            scatter!(ax, [r.nest]; legendmarkers["burrow"]..., color = RGBA(c, 0.75))
        end
        if !ismissing(r.pickup)
            scatter!(ax, [r.pickup]; legendmarkers["pickup"]..., color = RGBA(c, 0.75))
        end
        scatter!(ax, [r.dropoff]; legendmarkers["dropoff"]..., color = RGBA(c, 0.75))
        scatter!(ax, [r.fictive_nest]; legendmarkers["fictive burrow"]...)#, color = RGBA(c, 0.75))
        # m, M = extrema(first.(r.track.rawcoords.xy))
        # ax.xticks[] = m:1:M
        # m, M = extrema(last.(r.track.rawcoords.xy))
        # ax.yticks[] = m:1:M
        layout[2, 1] = LLegend(scene, apply_element(values(legendmarkers)), collect(keys(legendmarkers)), orientation = :horizontal, nbanks = 2, tellheight = true, height = Auto(), groupgap = 30);
        # limits!(ax, (-130, 130), (-200, 20))
        path = joinpath("quality", r.title)
        mkpath(path)
        FileIO.save(joinpath(path, "$(first(splitext(r.comment))).pdf"), scene)
    end
end
