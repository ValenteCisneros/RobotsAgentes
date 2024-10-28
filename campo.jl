using Agents, Random, Distributions, Statistics
using StaticArrays: SVector

@enum RobotStatus sinCaja withCaja

mutable struct PileInfo
    x::Int
    y::Int
    height::Int
end

@agent struct RobotAgent(ContinuousAgent{2}, Float64)
    status::RobotStatus = sinCaja
    accelerating::Bool = true
    target_pos::Union{Vector{Int}, Nothing} = nothing
    moves_count::Int = 0
end

@agent struct CajaAgent(GridAgent{2})
    in_pile::Bool = false
    pile_height::Int = 1
end

function initialize_model(; n_robots=5, n_cajas=40, extent=(40, 40))
    space2d = ContinuousSpace(extent; spacing=0.5)
    properties = Dict(
        :piles => Vector{PileInfo}(),
        :task_complete => false,
        :total_moves => 0,
        :start_time => time()
    )
    
    model = StandardABM(
        Union{RobotAgent, CajaAgent},
        space2d;
        properties=properties,
        scheduler=Schedulers.ByType(false, true)
    )

    # Agregar robots en posiciones aleatorias
    for _ in 1:n_robots
        pos = random_empty_position(model)
        add_agent!(
            RobotAgent,
            model,
            SVector{2, Float64}(0.0, 0.0),
            SVector{2, Float64}(pos[1], pos[2])
        )
    end

    # Agregar cajas en posiciones aleatorias
    for _ in 1:n_cajas
        pos = random_empty_position(model)
        add_agent!(CajaAgent, pos, model)
    end

    return model
end

function get_nearest_box(robot, model)
    min_dist = Inf
    nearest_box = nothing
    
    for box in allagents(model)
        if box isa CajaAgent && !box.in_pile
            dist = euclidean_distance(robot.pos, box.pos)
            if dist < min_dist
                min_dist = dist
                nearest_box = box
            end
        end
    end
    
    return nearest_box
end

function find_pile_space(model)
    for x in 1:model.extent[1]
        occupied = false
        current_height = 0
        
        for pile in model.piles
            if pile.x == x
                occupied = true
                current_height = pile.height
                break
            end
        end
        
        if !occupied || (occupied && current_height < 5)
            return [x, model.extent[2]]  # Devuelve un vector en lugar de tupla
        end
    end
    return nothing
end

function robot_step!(robot::RobotAgent, model)
    robot.moves_count += 1
    
    if robot.status == sinCaja
        # Buscar la caja más cercana
        nearest_box = get_nearest_box(robot, model)
        
        if !isnothing(nearest_box)
            # Moverse hacia la caja
            direction = normalize(nearest_box.pos - robot.pos)
            new_pos = robot.pos + direction * 0.5
            
            if !is_position_occupied(new_pos, model)
                move_agent!(robot, new_pos, model)
                
                # Si está lo suficientemente cerca, recoger la caja
                if euclidean_distance(robot.pos, nearest_box.pos) < 1.0
                    robot.status = withCaja
                    remove_agent!(nearest_box, model)
                end
            end
        end
    else  # robot tiene una caja
        if isnothing(robot.target_pos)
            robot.target_pos = find_pile_space(model)
        end
        
        if !isnothing(robot.target_pos)
            direction = normalize(SVector(robot.target_pos...) - robot.pos)
            new_pos = robot.pos + direction * 0.5
            
            if !is_position_occupied(new_pos, model)
                move_agent!(robot, new_pos, model)
                
                # Si llegó al destino, depositar la caja
                if euclidean_distance(robot.pos, SVector(robot.target_pos...)) < 1.0
                    push!(model.piles, PileInfo(robot.target_pos[1], robot.target_pos[2], 1))
                    robot.status = sinCaja
                    robot.target_pos = nothing
                end
            end
        end
    end
end

function model_step!(model)
    # Verificar si la tarea está completa
    boxes_in_piles = count(p -> p.height <= 5, model.piles)
    total_boxes = count(a -> a isa CajaAgent, allagents(model))
    
    if boxes_in_piles == total_boxes
        model.task_complete = true
        elapsed_time = time() - model.start_time
        println("Tarea completada en $(elapsed_time) segundos")
        
        # Calcular estadísticas de movimientos
        robot_moves = [a.moves_count for a in allagents(model) if a isa RobotAgent]
        avg_moves = mean(robot_moves)
        std_moves = std(robot_moves)
        println("Promedio de movimientos por robot: $(avg_moves)")
        println("Desviación estándar de movimientos: $(std_moves)")
    end
end

function run_simulation(n_robots, n_cajas, max_steps)
    model = initialize_model(n_robots=n_robots, n_cajas=n_cajas)
    
    for step in 1:max_steps
        if model.task_complete
            break
        end
        step!(model, robot_step!, model_step!)
    end
    
    return model
end
