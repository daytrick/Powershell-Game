Remove-Module Maze -Force
Import-Module ./Maze/Maze.psm1
# Using module ./Maze.psm1

Write-Output "Starting the game!"
$maze = GenerateMaze
$maze.Draw()