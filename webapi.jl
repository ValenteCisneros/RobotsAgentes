using Genie, Genie.Renderer.Json, Genie.Requests, HTTP
using UUIDs
include("campo.jl")  

instances = Dict()

# Ruta para crear una nueva simulación
route("/simulations", method = POST) do
    payload = jsonpayload()
    
    # Obtener parámetros básicos
    n_robots = get(payload, "n_robots", 5)
    n_cajas = get(payload, "n_cajas", 40)
    extent = get(payload, "extent", (40, 40))
    
    # Crear nueva instancia del modelo
    model = initialize_model(
        n_robots=n_robots,
        n_cajas=n_cajas,
        extent=extent
    )
    
    # Generar ID único para la simulación
    id = string(uuid1())
    instances[id] = model
    
    # Preparar respuesta con estado inicial
    robots = []
    cajas = []
    
    for agent in allagents(model)
        if agent isa RobotAgent
            push!(robots, Dict(
                "id" => agent.id,
                "pos" => agent.pos,
                "status" => agent.status,
                "moves_count" => agent.moves_count
            ))
        elseif agent isa CajaAgent
            push!(cajas, Dict(
                "id" => agent.id,
                "pos" => agent.pos,
                "in_pile" => agent.in_pile,
                "pile_height" => agent.pile_height
            ))
        end
    end
    
    json(Dict(
        "msg" => "Simulación creada",
        "location" => "/simulations/$id",
        "estado" => Dict(
            "robots" => robots,
            "cajas" => cajas,
            "piles" => model.piles,
            "task_complete" => model.task_complete
        )
    ))
end

# Ruta para ejecutar pasos de simulación
route("/simulations/:id/step", method = POST) do
    id = payload(:id)
    
    if !haskey(instances, id)
        return json(Dict("error" => "Simulación no encontrada"), status = 404)
    end
    
    model = instances[id]
    payload = try
        jsonpayload()
    catch
        Dict("steps" => 1)
    end
    
    n_steps = get(payload, "steps", 1)
    
    # Ejecutar pasos de simulación
    for _ in 1:n_steps
        step!(model, robot_step!, model_step!)
        if model.task_complete
            break
        end
    end
    
    # Preparar respuesta con estado actualizado
    robots = []
    cajas = []
    
    for agent in allagents(model)
        if agent isa RobotAgent
            push!(robots, Dict(
                "id" => agent.id,
                "pos" => agent.pos,
                "status" => agent.status,
                "moves_count" => agent.moves_count
            ))
        elseif agent isa CajaAgent
            push!(cajas, Dict(
                "id" => agent.id,
                "pos" => agent.pos,
                "in_pile" => agent.in_pile,
                "pile_height" => agent.pile_height
            ))
        end
    end
    
    # Calcular estadísticas si la tarea está completa
    stats = if model.task_complete
        robot_moves = [a.moves_count for a in allagents(model) if a isa RobotAgent]
        Dict(
            "tiempo_total" => time() - model.start_time,
            "promedio_movimientos" => mean(robot_moves),
            "desviacion_movimientos" => std(robot_moves)
        )
    else
        nothing
    end
    
    json(Dict(
        "msg" => "Simulación actualizada",
        "estado" => Dict(
            "robots" => robots,
            "cajas" => cajas,
            "piles" => model.piles,
            "task_complete" => model.task_complete,
            "statistics" => stats
        )
    ))
end

# Ruta para obtener estado actual
route("/simulations/:id", method = GET) do
    id = params(:id)
    
    if !haskey(instances, id)
        return json(Dict("error" => "Simulación no encontrada"), status = 404)
    end
    
    model = instances[id]
    
    # Preparar respuesta con estado actual
    robots = []
    cajas = []
    
    for agent in allagents(model)
        if agent isa RobotAgent
            push!(robots, Dict(
                "id" => agent.id,
                "pos" => agent.pos,
                "status" => agent.status,
                "moves_count" => agent.moves_count
            ))
        elseif agent isa CajaAgent
            push!(cajas, Dict(
                "id" => agent.id,
                "pos" => agent.pos,
                "in_pile" => agent.in_pile,
                "pile_height" => agent.pile_height
            ))
        end
    end
    
    json(Dict(
        "estado" => Dict(
            "robots" => robots,
            "cajas" => cajas,
            "piles" => model.piles,
            "task_complete" => model.task_complete
        )
    ))
end

# Ruta para eliminar una simulación
route("/simulations/:id", method = DELETE) do
    id = params(:id)
    
    if !haskey(instances, id)
        return json(Dict("error" => "Simulación no encontrada"), status = 404)
    end
    
    delete!(instances, id)
    json(Dict("msg" => "Simulación eliminada"))
end

# Configuración del servidor
Genie.config.run_as_server = true
Genie.config.cors_headers["Access-Control-Allow-Origin"] = "*"
Genie.config.cors_headers["Access-Control-Allow-Headers"] = "Content-Type"
Genie.config.cors_headers["Access-Control-Allow-Methods"] = "GET,POST,PUT,DELETE,OPTIONS" 
Genie.config.cors_allowed_origins = ["*"]

# Inicio del servidor
up()