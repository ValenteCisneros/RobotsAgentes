import { Button, ButtonGroup, SliderField } from '@aws-amplify/ui-react';
import { useRef, useState } from 'react';
import '@aws-amplify/ui-react/styles.css';
import Plotly from 'plotly.js/dist/plotly';

Plotly.newPlot('mydiv', [{
  y: [1, 2, 3, 1, 3],
  mode: 'lines',
  line: { color: '#80CAF6' }
}]);

function App() {
  let [location, setLocation] = useState("");
  let [gridSize, setGridSize] = useState(20);
  let [simSpeed, setSimSpeed] = useState(2);
  let [trees, setTrees] = useState([]);
  let [probability_of_spread, setProbability_of_spread] = useState(50);
  let [south_wind_speed, setSouth_wind_speed] = useState(0);
  let [west_wind_speed, setWest_wind_speed] = useState(0);
  let [big_jumps, setBigJumps] = useState(false);

  const running = useRef(null);
  const burntTrees = useRef(null);

  let setup = () => {
    fetch("http://localhost:8000/simulations", {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        dim: [gridSize, gridSize],
        probability: probability_of_spread,
        south_wind_speed: south_wind_speed,
        west_wind_speed: west_wind_speed,
        big_jumps: big_jumps,
      })
    }).then(resp => resp.json())
      .then(data => {
        setLocation(data["Location"]);
        setTrees(data["trees"]);
      });
  }

  let handleStart = () => {
    burntTrees.current = [];
    running.current = setInterval(() => {
      fetch("http://localhost:8000" + location)
        .then(res => res.json())
        .then(data => {
          let burnt = data["trees"].filter(t => t.status == "burnt").length / data["trees"].length;
          burntTrees.current.push(burnt);
          setTrees(data["trees"]);
        });
    }, 1000 / simSpeed);
  };

  let handleStop = () => {
    clearInterval(running.current);

    Plotly.newPlot('mydiv', [{
      y: burntTrees.current,
      mode: 'lines',
      line: { color: '#80CAF6' }
    }]);
  };

  let burning = trees.filter(t => t.status == "burning").length;
  if (burning == 0) handleStop();
  let offset = (500 - gridSize * 12) / 2;

  return (
    <>
      <ButtonGroup variation="primary">
        <Button onClick={setup}>Setup</Button>
        <Button onClick={handleStart}>Start</Button>
        <Button onClick={handleStop}>Stop</Button>
      </ButtonGroup>

      <SliderField label="Simulation Speed" min={1} max={40} step={2}
        value={simSpeed} onChange={setSimSpeed} />

      <SliderField label="Grid size" min={10} max={40} step={10}
        value={gridSize} onChange={setGridSize} />

      <SliderField label="Probability of Spread" min={1} max={100} step={1}
        value={probability_of_spread} onChange={setProbability_of_spread} />

      <SliderField label="South-North Wind Speed" min={-50} max={50} step={1}
        value={south_wind_speed} onChange={setSouth_wind_speed} />

      <SliderField label="West-East Wind Speed" min={-50} max={50} step={1}
        value={west_wind_speed} onChange={setWest_wind_speed} />

      <SliderField label="Enable Big Jumps" min={0} max={1} step={1}
        value={big_jumps ? 1 : 0} onChange={(value) => setBigJumps(value === 1)} />

      <svg width="500" height="500" xmlns="http://www.w3.org/2000/svg" style={{ backgroundColor: "white" }}>
        {
          trees.map(tree =>
            <image
              key={tree["id"]}
              x={offset + 12 * (tree["pos"][0] - 1)}
              y={offset + 12 * (tree["pos"][1] - 1)}
              width={15} href={
                tree["status"] === "green" ? "./greentree.svg" :
                  (tree["status"] === "burning" ? "./burningtree.svg" :
                    "./burnttree.svg")
              }
            />
          )
        }
      </svg>
    </>
  )
}

export default App;
