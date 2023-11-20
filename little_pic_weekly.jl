using YAXArrays, NetCDF
using DimensionalData
using Statistics
using CairoMakie
using Zarr
using CoordinateTransformations, Rotations

struct DirectedDrop{T<:AbstractVector}
    c::T
    θ::Float64
end

function circleShape(h,k,r; repeat = 5)
    θ = range(0, 2π, 52*repeat)
    return [Point2f(h + r*sin(θi), k + r*cos(θi)) for θi in θ]
end

# city = "Sitka, Alaska."
# scity = "sitka"

cities = ["Sitka, Alaska.", "Hilo, Hawai.", "Buenaventura, Colombia.",
    "Carna, Ireland.", "Kelardasht, Iran", "Timika, Indonesia.",
    "Niefang, Equatorial Guinea.", "Frascati, Italy.", "Jena, Germany."]
scities = ["sitka", "hilo", "buenaventura", "carna", "kelardasht",
    "timika", "niefang", "frascati", "jena"]

for (c, city) in enumerate(cities)
    scity = scities[c]
    f10_prints = open_dataset(joinpath(@__DIR__, "./data/tp_weekly_$(scity).zarr/"))
    f10_prints  = Cube(f10_prints).data[:,:]

    pnts = circleShape(0,0,1);
    mn = minimum(f10_prints)
    mx = maximum(f10_prints)
    @show mn, mx, scity
    function droplet(x::DirectedDrop)
        f = Translation(x.c) ∘ LinearMap(Angle2d(x.θ))
        n = 64
        pnts = [f(Point2f(cos(t), sin(t)*sin(t/2)^2)) for t in range(0, 2π, n + 1)[1:end-1]]
        pnts
    end

    c = Point2f(0,0)
    dd = DirectedDrop(c, pi/2)
    ndrops = 10
    rdrops = range(mn+ 1e-10, mx +1e-10, ndrops)
    ms = 2000*rdrops .+ 10

    using Random
    Random.seed!(133)
    locs_drops = Point2f.(range(-2.1,2.1, ndrops), 2.3)

    shift_d = [Point2f(0, -1), Point2f(-0.3, -0.1), Point2f(-0.4, -0.3), Point2f(-0.5, 0.1), Point2f(-0.5, 0.0),
        Point2f(0.5, 0.0), Point2f(0.5, 0), Point2f(0.5, -0.4), Point2f(0.3, -0.1), Point2f(0.1, -0.9)
        ]

    locs_drops = locs_drops .+ shift_d
    drops_array = [droplet(dd)*ms[k]/300 .+ locs_drops[k] for (k,i) in enumerate(locs_drops)]

    set_theme!(theme_light())
    let
        for bgc in [:white, :black]
            txt_color = bgc == :white ? :black : :white

            fig = Figure(figure_padding=0, resolution = (1414,2000),font="CMU Serif", backgroundcolor=:white)
            ax = Axis(fig[1,1], aspect = 1, backgroundcolor=bgc)
            ax_title = Axis(fig[2,1], height=586, backgroundcolor="#f0eedf")
            arrows!(ax, [-0.1], [-0.1], [-2], [-2], arrowsize = 0, arrowtail=0.0,
                color = (txt_color,0.85), linewidth=4)
            arrows!(ax,[-2], [-2], [-0.4], [-0.4], color = txt_color,  arrowsize = 0, linewidth=13)
            for (k,i) in enumerate(range(0.25,2,20))
                lines!(ax, circleShape(0,0,i); color = repeat(f10_prints[:,k] .+1e-10, inner=5),
                    linewidth=20, colormap= :managua, colorscale=log10,
                    colorrange = (mn .+ 1e-10, mx+1e-10))
            end
            pnts = circleShape(0,0,2.15)
            pnts_t = circleShape(0,0,2.28)
            lines!(ax, pnts; color = 1:length(pnts), linewidth= 5,
                colormap = resample_cmap(:tableau_blue_green, 100, alpha = range(0.35,1,100)))
            arrows!(ax, [0], [2.15], [0.01], [0], arrowsize = 40, color = (txt_color ,0.75))
            arrows!(ax, [2.15], [0], [0.0], [-0.01], arrowsize = 40, color = (txt_color ,0.75))
            arrows!(ax, [0], [-2.15], [-0.01], [0.0], arrowsize = 40, color = (txt_color ,0.75))
            arrows!(ax, [-2.15], [0], [0.0], [0.01], arrowsize = 40, color = (txt_color ,0.75))

            text!(ax, pnts_t[1:24:end], text = string.(1:5:52), align = (:center, :center),
                 fontsize = 42, color = txt_color, font=:bold)
            poly!(ax, drops_array, 
                color = rdrops,
                colormap= :managua, colorscale=log10,
                colorrange = (mn+1e-10, mx+1e-10)
            )
            text!(ax, [Point2f(0,0), Point2f(-1.7,-1.7)], text = ["2003", "2022"],
                fontsize = 32, font=:bold,
                color = txt_color , align=[(:center, :center),(:right, :bottom)])
            text!(ax_title, Point2f(0,-0.85),
                text = rich("Weekly mean total rainfall\n\n\n", fontsize = 64, font=:bold,
                    rich("2003-2022\n\n\n", fontsize = 42, font=:bold),
                    rich("What week has been the most rainy? This little picture illustrates\n\nthe weekly mean total rainfall per year and across several years in\n\n", fontsize = 38, font=:regular), rich(city, font=:bold, fontsize=38)),
                align = (:left, :center),
                color = :black)   

            hidedecorations!(ax)
            hidespines!(ax)
            hidedecorations!(ax_title)
            hidespines!(ax_title)

            limits!(ax_title, -0.2,5,-2.5,0.5)
            limits!(ax, -2.5,2.5,-2.5,2.5)
            colgap!(fig.layout, 0)
            rowgap!(fig.layout, 0)
            save("./little_pictures/$(bgc)/rainfall_weekly_$(scity).png", fig)
        end
    end
end