using GLMakie
using HDF5
using ProgressMeter


## Load the data
hid = h5open("combined_results.h5", "r")

# initialize arrays
n_events = length(keys(hid["events"]))
n_t = length(read(hid["events/0/orbit"])[1:end, 1])
lines_data = fill(NaN, (n_events * (n_t + 1), 3))
# load the data and concatenate them to create only one line object
@showprogress for (i, i_event) in enumerate(keys(hid["events"]))
    string_dataset = "events/" * i_event * "/orbit"
    data = read(hid[string_dataset])
    lines_data[(1:n_t) .+ 1 .+ (i - 1) * (n_t + 1), :] .= data[1:end, 1:3]
end

close(hid)



## Plot the data (animate one meteor)
points1 = Observable(Point3f[])
points2 = Observable(Point3f[])
points3 = Observable(Point3f[])
colors = Observable(Int[])

set_theme!(theme_black())
f = Figure()
ax = Axis3(f[1, 1])
l1 = lines!(points1, color = colors, colormap = :inferno, transparency = true)
l2 = lines!(points2, color = colors, colormap = :inferno, transparency = true)
l3 = lines!(points3, color = colors, colormap = :inferno, transparency = true)
xlims!(-10 * 150e9, 10 * 150e9)
ylims!(-10 * 150e9, 10 * 150e9)
zlims!(-10 * 150e9, 10 * 150e9)
display(f)
set_theme!()

# animate
while true
    isopen(f.scene) || break # exit if window is closed
    for i_t in 1:n_t
        isopen(f.scene) || break  # exit if window is closed

        push!(points1[], lines_data[i_t + 1, :])
        push!(points2[], lines_data[2 * (n_t + 1) + i_t + 1, :])
        push!(points3[], lines_data[4 * (n_t + 1) + i_t + 1, :])
        push!(colors[], i_t)
        notify(points1)
        notify(points2)
        notify(points3)
        notify(colors)
        l1.colorrange = (0, length(points1[]))
        l2.colorrange = (0, length(points2[]))
        l3.colorrange = (0, length(points3[]))
        if length(points1[]) > 1000
            popfirst!(points1[])
            popfirst!(points2[])
            popfirst!(points3[])
        end

        sleep(0.001)
    end

    points1.val = Point3f[]
    points2.val = Point3f[]
    points3.val = Point3f[]
    colors.val = Int[]
    notify(points1)
    notify(points2)
    notify(points3)
    notify(colors)
end
