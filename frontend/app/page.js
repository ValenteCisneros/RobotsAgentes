'use client'
import { useRef, useState } from "react";
import styles from "./page.module.css";
import {Box, Button, Grid2, Input, Slider, Typography } from "@mui/material";

export default function Home() {
  let [location, setLocation] = useState("");
  let [trees, setTrees] = useState([]);
  let [gridSize, setGridSize] = useState(20);
  const running = useRef(null);

  let setup = () => {
    console.log("Hola");
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

  const handleStart = () => {
    running.current = setInterval(() => {
      fetch("http://localhost:8000" + location)
      .then(res => res.json())
      .then(data => {
        setTrees(data["trees"]);
      });
    }, 500);
  };

  const handleStop = () => {
    clearInterval(running.current);
  }

  const handleGridSizeSliderChange = (event, newValue) => {
    setGridSize(newValue);
  };

  let burning = trees.filter(t => t.status == "burning").length;

  if (burning == 0)
    handleStop();

  let offset = (500 - gridSize * 12) / 2;
  return (
    <main className={styles.main}>
      <div>
        <Button variant={"contained"} onClick={setup}>pause</Button>
        <Button variant={"contained"} onClick={setup}>
          Setup
        </Button>
        <Button variant={"contained"} onClick={handleStart}>
          Start
        </Button>
        <Button variant={"contained"} onClick={handleStop}>
          Stop
        </Button>
      </div>
<Box sx={{ width: 250 }}>
  <Typography id="input-slider" gutterBottom>
    Grid size
  </Typography>
  <Grid2 container spacing={2} alignItems="center">
    <Grid2 xs>
      <Slider sx={{ width: 190 }}
        value={gridSize} 
        onChange={handleGridSizeSliderChange}
        defaultValue={20} step={10} marks min={10} max={40} valueLabelDisplay="auto" />
    </Grid2>
    <Grid2>
      <Input
        value={gridSize}
        inputProps={{step: 10, min: 10, max: 40, type: 'number'}} 
      />
    </Grid2>
  </Grid2>
</Box>
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
    </main>
  );
}