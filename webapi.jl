include("forest.jl")
using Genie, Genie.Renderer.Json, Genie.Requests, HTTP
using UUIDs

instances = Dict()

# Ruta para crear una nueva simulación
route("/simulations", method = POST) do
    payload = jsonpayload()
    x = payload["dim"][1]
    y = payload["dim"][2]
    probability = payload["probability"]
    
    # Parámetros adicionales
    south_wind_speed = get(payload, "south_wind_speed", 0)
    west_wind_speed = get(payload, "west_wind_speed", 0)
    big_jumps = get(payload, "big_jumps", false)

    # Creación del modelo forest_fire con los parámetros recibidos
    model = forest_fire(griddims=(x, y), 
                        probability = probability, 
                        south_wind_speed = south_wind_speed, 
                        west_wind_speed = west_wind_speed, 
                        big_jumps = big_jumps)
                        
    id = string(uuid1())
    instances[id] = model

    trees = []
    for tree in allagents(model)
        push!(trees, tree)
    end
    
    # Respuesta con la ubicación del modelo y el estado inicial de los árboles
    json(Dict(:msg => "Simulación creada", "Location" => "/simulations/$id", "trees" => trees))
end

# Ruta para ejecutar una simulación existente
route("/simulations/:id") do
    model = instances[payload(:id)]
    run!(model, 1)
    trees = []
    for tree in allagents(model)
        push!(trees, tree)
    end
    
    # Respuesta con el estado actualizado de los árboles
    json(Dict(:msg => "Simulación actualizada", "trees" => trees))
end

# Configuración del servidor
Genie.config.run_as_server = true
Genie.config.cors_headers["Access-Control-Allow-Origin"] = "*"
Genie.config.cors_headers["Access-Control-Allow-Headers"] = "Content-Type"
Genie.config.cors_headers["Access-Control-Allow-Methods"] = "GET,POST,PUT,DELETE,OPTIONS" 
Genie.config.cors_allowed_origins = ["*"]

# Inicio del servidor
up()
