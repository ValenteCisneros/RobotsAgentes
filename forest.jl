using Agents, Random, Distributions

@enum TreeStatus green burning burnt

@agent struct TreeAgent(GridAgent{2})
    status::TreeStatus = green
    probability::Float64 = 0.0
end

function forest_step(tree::TreeAgent, model)
    if tree.status == burning
        if model.big_jumps == 0
            for neighbor in nearby_agents(tree, model)
                if neighbor.status == green
                    dx = neighbor.pos[1] - tree.pos[1]
                    dy = neighbor.pos[2] - tree.pos[2]

                    wind_adjustment = 0
                    if dx == 0 && dy == 1  # Norte
                        wind_adjustment += model.south_wind_speed
                    elseif dx == 0 && dy == -1  # Sur
                        wind_adjustment -= model.south_wind_speed
                    elseif dx == 1 && dy == 0  # Este
                        wind_adjustment += model.west_wind_speed
                    elseif dx == -1 && dy == 0  # Oeste
                        wind_adjustment -= model.west_wind_speed
                    elseif dx == 1 && dy == 1  # Noreste (diagonal)
                        wind_adjustment += (model.south_wind_speed + model.west_wind_speed) / 2
                    elseif dx == -1 && dy == -1  # Suroeste (diagonal)
                        wind_adjustment -= (model.south_wind_speed + model.west_wind_speed) / 2
                    end

                    adjusted_probability = clamp(model.probability_of_spread + wind_adjustment, 0, 100)
                    rand_val = rand(0:100)
                    if rand_val < adjusted_probability
                        neighbor.status = burning
                    end
                end
            end
        elseif model.big_jumps == 1
            scale_factor = 15
            distant_dx = Int(round(model.west_wind_speed / scale_factor))
            distant_dy = Int(round(model.south_wind_speed / scale_factor))
            distant_pos = (tree.pos[1] + distant_dx, tree.pos[2] + distant_dy)
            distant_tree = agents_in_position(distant_pos, model)
            if distant_tree !== nothing && distant_tree.status == green
                distant_tree.status = burning
            end
        end
        tree.status = burnt
    end
end

function forest_fire(; density = 0.85, griddims = (5, 5), probability = 1.0, south_wind_speed = 0, west_wind_speed = 0, big_jumps = 0)
    space = GridSpaceSingle(griddims; periodic = false, metric = :manhattan)
    properties = (south_wind_speed = south_wind_speed, west_wind_speed = west_wind_speed, probability_of_spread = probability, big_jumps = big_jumps)
    forest = StandardABM(TreeAgent, space; agent_step! = forest_step, scheduler = Schedulers.Randomly(), properties = properties)
    for pos in positions(forest)
        if rand(Uniform(0,1)) < density
            tree = add_agent!(pos, forest)
            if pos[1] == 1
                tree.status = burning
                tree.probability = probability
            end
        end
    end
    return forest
end
