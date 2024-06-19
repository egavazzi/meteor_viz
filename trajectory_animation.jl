
using GLMakie
using HDF5
using ProgressMeter

function plotfun()

    ## Load the data
    hid = h5open("../maarsy_meteors/daniel/results/combined_results.h5", "r")

    vel = read(hid["vels"])
    vel[vel .> 70000] .= 70000
    vel[vel .< 10000] .= 10000

    # this is so messed up
    # the event key is index 0..n-1 to
    # arrays like vel
    event_keys=[]
    eks=keys(hid["events"])
    for i in 1:length(eks)
        push!(event_keys,parse(Int,eks[i]))
    end
    
    # initialize arrays
    n_events = length(keys(hid["events"]))
    n_t = length(read(hid["events/0/orbit"])[1:end, 1])
    lines_data = fill(NaN, (n_events * (n_t + 1), 3))
    # load the data and concatenate them to create only one line object
    @showprogress for (i, i_event) in enumerate(keys(hid["events"]))
        string_dataset = "events/" * i_event * "/orbit"
        data = read(hid[string_dataset])
        
        lines_data[n_t*i .+ (1:n_t), :] .= data[1:end, 1:3]
    end

    close(hid)
    
    set_theme!(theme_black())
    f = Figure()
    ax = Axis3(f[1, 1])
    max_au=5
    xlims!(-max_au * 150e9, max_au * 150e9)
    ylims!(-max_au * 150e9, max_au * 150e9)
    zlims!(-max_au * 150e9, max_au * 150e9)
    display(f)


    pointlist=[]
    linelist=[]
    evidx=[]
    n_lines=1000
    colors = Observable(Int[])
    n_colors=10
    for i = 1:n_lines
        o=Observable(Point3f[])
        push!(pointlist,o)
        idx=Int(round(rand()*n_events+1))
        push!(evidx,idx)
#        l=lines!(o, color = colors, colormap = :grays, transparency = true, alpha=0.2)
        l=lines!(o, color = vel[event_keys[idx]+1], colorrange=(10e3,70e3), colormap=:turbo, transparency = true, alpha=0.2)        
#        l.colorrange = (0, n_colors)#ceil(n_t/10))
        push!(linelist,l)
    end
    
    
    # animate
    while true
        println("entering draw loop")
        isopen(f.scene) || break # exit if window is closed
 #       color_idx=0
        for i_t in 1:10:n_t
            isopen(f.scene) || break  # exit if window is closed
#            push!(colors[], color_idx)            
            for i = 1:n_lines
                push!(pointlist[i][], lines_data[evidx[i]*n_t + i_t, :])
                notify(pointlist[i]  )
                if length(pointlist[i][]) > n_colors
                    popfirst!(pointlist[i][])
                end
            end
#            println("update positions")
  #          color_idx+=1
#            notify(colors)
            sleep(0.0000001)
        end
        for i = 1:n_lines
            pointlist[i].val=Point3f[]
            
            notify(pointlist[i])
        end
        
        # randomize events to plot
        for i = 1:n_lines
            evidx[i]=Int(round(rand()*n_events+1))
            linelist[i]= lines!(pointlist[i], color = vel[evidx[i]+1], colorrange=(10e3,70e3), colormap=:turbo, transparency = true, alpha=0.2)        
        end
#        colors.val=Int[]
 #       notify(colors)
    end
end



plotfun()
