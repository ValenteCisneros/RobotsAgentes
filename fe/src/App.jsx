import { Button, ButtonGroup, SliderField } from '@aws-amplify/ui-react';
import { useRef, useState } from 'react'

import '@aws-amplify/ui-react/styles.css';

import Plotly from 'plotly.js/dist/plotly';

Plotly.newPlot('mydiv', [{
  y: [1,2,3,1,3],
  mode: 'lines',
  line: {color: '#80CAF6'}
}]);

function App() {
  let [location, setLocation] = useState("");
  let [gridSize, setGridSize] = useState(20);
  let [simSpeed, setSimSpeed] = useState(2);
  let [trees, setTrees] = useState([]);

  const running = useRef(null);

  const burntTrees = useRef(null);

  let setup = () => {
    fetch("http://localhost:8000/simulations", {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ dim: [gridSize, gridSize] })
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
      }, 1000/ simSpeed );
  };
  
  let handleStop = () => {
    clearInterval(running.current);
  
    Plotly.newPlot('mydiv', [{
      y: burntTrees.current,
      mode: 'lines',
      line: {color: '#80CAF6'}
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

      <svg width="500" height="500" xmlns="http://www.w3.org/2000/svg" style={{backgroundColor:"white"}}>
      {
        trees.map(tree =>
          <image
            key={tree["id"]}
            x={offset + 12*(tree["pos"][0] - 1)}
            y={offset + 12*(tree["pos"][1] - 1)}
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

export default App