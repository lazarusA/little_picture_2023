using CairoMakie
using CairoMakie.FileIO

scities = ["buenaventura", "Timika", "sitka", "carna", "kelardasht", "hilo",
"niefang", "frascati", "jena"]

function load_img(; bgc = :black, scity="jena")
    path = "./little_pictures/$(bgc)/rainfall_by_hour_$(scity).png"
    return FileIO.load(path)
end

# black version
imgs = [load_img(; scity = c) for c in scities]

fig = Figure(figure_padding=0, resolution = (1414*3,2000*3))
axs = [Axis(fig[i,j], aspect = DataAspect()) for i in 1:3 for j in 1:3]
hidedecorations!.(axs)
hidespines!.(axs)
[image!(axs[k], rotr90(imgs[k])) for k in 1:9]
colgap!(fig.layout, 5)
rowgap!(fig.layout, 5)
fig
save("./little_pictures/black/grid_black.png", fig)

# white version
imgs = [load_img(; bgc=:white, scity = c) for c in scities]

fig = Figure(figure_padding=0, resolution = (1414*3,2000*3))
axs = [Axis(fig[i,j], aspect = DataAspect()) for i in 1:3 for j in 1:3]
hidedecorations!.(axs)
hidespines!.(axs)
[image!(axs[k], rotr90(imgs[k])) for k in 1:9]
colgap!(fig.layout, 5)
rowgap!(fig.layout, 5)
fig
save("./little_pictures/white/grid_white.png", fig)