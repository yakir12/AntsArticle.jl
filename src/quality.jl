function plotquality(df)
    legendmarkers["feeder"] = (color = :black, marker = '▴', strokecolor = :black, markerstrokewidth = 0.5, strokewidth = 0.5, markersize = 15px)
    delete!(legendmarkers, "mean ± FWHM")
    polys = OrderedDict(string(df.group[1]) => (color = df.groupcolor[1], strokecolor = :transparent))
    for (i, r) in enumerate(eachrow(df))
        c = r.groupcolor
        scene, layout = layoutscene()#0, resolution = (2max_width, 900.0))
        ax = layout[1,1] = LAxis(scene)
        lines!(ax, homing(r.track))#; legendmarkers["track"]..., color = :red)
        lines!(ax, searching(r.track); legendmarkers["track"]..., color = c)
        scatter!(ax, [turningpoint(r.track)]; legendmarkers["turning point"]..., color = RGBA(c, 0.75))
        scatter!(ax, [searchcenter(r.track)]; legendmarkers["center of search"]..., color = RGBA(c, 0.75))
        scatter!(ax, [r.feeder]; legendmarkers["feeder"]..., color = RGBA(c, 0.75))
        if !ismissing(r.nest)
            scatter!(ax, [r.nest]; legendmarkers["burrow"]..., color = RGBA(c, 0.75))
        end
        scatter!(ax, [r.fictive_nest]; legendmarkers["fictive burrow"]...)#, color = RGBA(c, 0.75))
        layout[2, 1] = LLegend(scene, apply_element.(values.([polys, legendmarkers])), collect.(keys.([polys, legendmarkers])), ["Direction of displacements", " "], orientation = :horizontal, nbanks = 2, tellheight = true, height = Auto(), groupgap = 30);
        FileIO.save("$i.pdf", scene)
    end
end
