using Agents, Random, Distributions

@enum TreeStatus green burning burnt

@agent struct TreeAgent(GridAgent{2})
    status::TreeStatus = green
    probability::Float64 = 0.0
end

function forest_step(tree::TreeAgent, model)
    if tree.status == burning
        for neighbor in nearby_agents(tree, model)
            neighbor.probability = rand(0:100)
            if neighbor.status == green && model.probability <= neighbor.probability
                neighbor.status = burning
            end
        end
        tree.status = burnt
    end
end

function forest_fire(; density = 0.45, griddims = (5, 5), probability = 1.0)
    properties = Dict(:probability=> probability)
    space = GridSpaceSingle(griddims; periodic = false, metric = :manhattan)
    forest = StandardABM(TreeAgent, space; agent_step! = forest_step, scheduler = Schedulers.Randomly(), properties)
    for pos in positions(forest)
        if rand(Uniform(0,1)) < density
            tree = add_agent!(pos, forest)
            if pos[1] == 1
                tree.status = burning
            end
        end
    end
    return forest
end
