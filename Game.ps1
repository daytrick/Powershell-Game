########## GAME ##########

# State
$STATES = @{START = "start"; PLAYING = "playing"; ENDED = "ENDED"}
$state = $STATES.START

# Maze dimensions
$dim = 10
$growRate = 5
$maxDim = 20

# Display maze
$maze = [Maze]::new($dim, $dim)
$maze.PartitionGrid()

# Game loop
$count = 1
$finished = $false
while (-not $finished) {

    switch ($state) {

        # Start screen
        $STATES.START { 
            Clear-Host
            Write-Host 'Powershell Maze Game'
            Read-Host 'Press any key to start'
            $state = $STATES.PLAYING
        }

        # Game
        $STATES.PLAYING {

            # Display maze
            $mazeString = $maze.GetStringRep()
            Clear-Host
            Write-Output ("Maze " + $count) "Use WASD to move."
            Write-Output $mazeString

            $key = [System.Console]::ReadKey()
            if ($key.Key -eq 'escape') {
                $state = $STATES.ENDED
                break
            }
            else {
                $maze.MovePlayer($key)
            } 

            # Check for win condition
            if ($maze.Goal.HasPlayer) {

                # Inform player
                Clear-Host
                Write-Host "MAZE SOLVED"
                Start-Sleep -Seconds 1

                # Update maze size
                $count++
                if (($dim -lt $maxDim) -and ($count % $growRate -eq 1)) {
                    $dim++
                }

                # Generate new maze
                $maze = [Maze]::new($dim, $dim)
                $maze.PartitionGrid()

            }

            break

        }

        # End screen
        $STATES.ENDED {

            # Inform player how many got solved
            Clear-Host
            $solved = $count - 1
            Write-Host "xYou solved ${solved} mazes this time."
            Write-Host

            # Ask if want to play again
            $again = Read-Host "Would you like to play again? (Y/N)"
            if ($again -eq "Y") {
                $count = 1
                $dim = 10
                $maze = [Maze]::new($dim, $dim)
                $maze.PartitionGrid()
                $state = $STATES.PLAYING
            }
            else {
                $finished = $true
            }
            
        }

    }

}

# Write-Output $maze.Grid | Sort-Object -Property Order

########## CELL ##########

<#
Cell representation.
#>
class Cell {

    # Record where it is on the grid
    [int] $r
    [int] $c

    # Record info about neighbours
    [Hashtable] $Walls
    [Boolean]   $Peeked
    [Boolean]   $Visited
    [Cell]      $PeekedFrom
    [Cell]      $PrevCell
    [int]       $PeekR
    [int]       $PeekC
    [int]       $Order

    # Record status
    [Boolean]   $HasPlayer
    [Boolean]   $IsGoal

    # Constructor
    Cell([int] $c, [int] $r) {
        $this.c = $c
        $this.r = $r
        $this.Walls = @{N = $true; E = $true; S = $true; W = $true}
        Write-Output "walls: " $this.Walls
        $this.Peeked = $false
        $this.Visited = $false
        $this.PrevCell = $null
        $this.PeekedFrom = $null
        $this.PeekR = $null
        $this.PeekC = $null
        $this.Order = 0
        $this.HasPlayer = $false
    }

    # Peek at the cell
    [Void] Peek([Cell] $peekedFrom) {
        $this.PeekedFrom = $peekedFrom
        $this.Peeked = $true
        $this.PeekR = $peekedFrom.r
        $this.PeekC = $peekedFrom.c
    }

    # Visit the cell
    [Boolean] Visit([Cell] $currentCell, [int] $order) {

        # Don't visit if already been
        if ($this.Visited) {
            return $false
        }
        
        # Otherwise, visit the cell
        $this.Visited = $true
        $this.Order = $order

        # Mark cell
        if (-not ($null -eq $currentCell)) {
        
            $this.PrevCell = $currentCell
            
            # Work out which wall to toggle
            if ($currentCell.r -lt $this.r) {
                $this.Walls.N = $false
                $currentCell.Walls.S = $false
            }
            elseif ($currentCell.r -gt $this.r) {
                $this.Walls.S = $false
                $currentCell.Walls.N = $false
            }
            elseif ($currentCell.c -lt $this.c) {
                $this.Walls.W = $false
                $currentCell.Walls.E = $false
            }
            else {
                $this.Walls.E = $false
                $currentCell.Walls.W = $false
            }

        }

        # Indicate successful visitation
        return $true

    }

    # Get string rep of the SE corner of this cell.
    [String] GetStringRep() {

        # Only consider SE walls on assumption that neighbouring cells will draw your NW walls
        $rep = ''

        if ($this.Walls.S) {

            # How to print underlined text from: https://www.reddit.com/r/PowerShell/comments/d74lce/comment/f0xhbv3/?utm_source=share&utm_medium=web3x&utm_name=web3xcss&utm_term=1&utm_content=share_button
            if ($this.HasPlayer) {
                $rep += "$([char]27)[4mo$([char]27)[24m"
            }
            elseif ($this.IsGoal) {
                $rep += "$([char]27)[4mX$([char]27)[24m"
            }
            else {
                $rep += '_'
            }
            
        }
        elseif ($this.HasPlayer) {
            $rep += 'o'
        }
        elseif ($this.IsGoal) {
            $rep += 'X'
        }
        else {
            $rep += ' '
        }

        if ($this.Walls.E) {
            $rep += '|'
        }
        else {
            $rep += ' '
        }

        return $rep

    }

}

########## MAZE ##########

<#
Maze representation.
#>
class Maze {

    [int] $Width
    [int] $Height

    [Cell[,]] $Grid
    [Cell] $Goal

    # Record player location
    [Player] $Player

    Maze([int] $width, [int] $height) {

        $this.Width = $width
        $this.Height = $height

        Write-Output "Generating the maze!"
        $this.GenerateMaze()

        $this.Player = [Player]::new($this)

    }

    <#
    Generate the basic maze (no connections between cells yet).
    #>
    [void] GenerateMaze() {

        Write-Output "In GenerateMaze!"

        $this.Grid = New-Object 'Cell[,]' $this.Height,$this.Width

        for ([int] $r = 0; $r -lt $this.Height; $r++) {
            for ([int] $c = 0; $c -lt $this.Width; $c++) {
                $this.Grid[$c, $r] = [Cell]::new($c, $r)
            }
        }

        $this.Goal = $this.Grid[($this.Width - 1), ($this.Height - 1)]
        $this.Goal.IsGoal = $true

    }


    <#
    Partition the maze.
    Uses randomised depth-first search: https://en.wikipedia.org/wiki/Maze_generation_algorithm#Iterative_implementation_(with_stack)
    #>
    [int16] PartitionGrid() {

        # Choose random initial cell
        $r = Get-Random -Maximum $this.Height
        $c = Get-Random -Maximum $this.Width
        $start = $this.Grid[$c, $r]
        $start.Visit($null, 1)

        # Create stack and initialise
        $stack = New-Object System.Collections.Stack
        $stack.Push($start)

        $visitations = 1
        # While stack not empty ...
        while ($stack.Count -gt 0) {

            # ... set current cell to top of stack
            $currCell = $stack.Pop()

            # Keep going if can (have at least one unvisited neighbour)
            $neighbour = $this.PickRandomUnvisitedNeighbourOf($currCell)
            if (($null -ne $neighbour)) {
                $stack.Push($currCell)
                $visitations++
                $neighbour.Visit($currCell, $visitations)
                $stack.Push($neighbour)
            }

        }

        return $visitations
        
    }


    <#
    Pick a random unvisited neighbour of the provided cell.
    Returns null if no more unvisited neighbours.
    #>
    [Cell] PickRandomUnvisitedNeighbourOf([Cell] $currCell) {

        $order = 'E','N','S','W' | Sort-Object {Get-Random}

        for ($i = 0; $i -lt $order.Count; $i++) {
            
            $r = $currCell.r
            $c = $currCell.c
            switch ($order[$i]) {
                'N' { 
                    $r-- 
                    break
                }
                'E' {
                    $c++ 
                    break
                }
                'S' { 
                    $r++ 
                    break
                }
                'W' { 
                    $c-- 
                    break
                }
            }

            $inR = ((0 -le $r) -and ($r -lt $this.Height))
            $inC = ((0 -le $c) -and ($c -lt $this.Width))
            if ($inR -and $inC) {
                $neighbour = $this.Grid[$c, $r]
                if (-not $neighbour.Visited) {
                    return $neighbour
                }
            }

        }

        return $null
        
    }


    [void] MovePlayer([System.ConsoleKeyInfo] $key) {

        $this.Grid[$this.Player.c, $this.Player.r].HasPlayer = $false
        $this.Player.Move($key)
        $this.Grid[$this.Player.c, $this.Player.r].HasPlayer = $true

    }




    <#
    Get a string representation of the maze.
    #>
    [String] GetStringRep() {

        $stringRep = ''

        $topBorder = '_'
        for ($c = 0; $c -lt $this.Width; $c++) {
            $topBorder += "__"
        }
        $stringRep += $topBorder + "`n"

        for ($r = 0; $r -lt $this.Height; $r++) {
            $stringRep += $this.GetRowStringRep($r) + "`n"
        }

        return $stringRep

    }

    <#
    Get a string representation of a row of the maze.
    #>
    [String] GetRowStringRep([int] $r) {

        $row = '|'

        for ($c = 0; $c -lt $this.Width; $c++) {
            $row += $this.Grid[$c,$r].GetStringRep()
        }

        return $row

    }

}

########## PLAYER ##########
class Player {

    [String] $LEFT     = 'A'
    [String] $UP       = 'W'
    [String] $RIGHT    = 'D'
    [String] $DOWN     = 'S'

    [Maze] $Maze
    [String] $symbol
    [int] $c
    [int] $r
    
    Player([Maze] $maze) {
        $this.Maze = $maze
        $this.Maze.Grid[0,0].HasPlayer = $true
        $this.symbol = 'x̲'
        $this.c = 0
        $this.r = 0
    }

    [void] Move([System.ConsoleKeyInfo] $key) {

        $currCell = $this.Maze.Grid[$this.c, $this.r]

        # Make sure player doesn't go out of bounds, or ghost through walls
        # How to determine which key gets pressed from: https://stackoverflow.com/a/48662114
        switch ($key.Key) {
            $this.UP {
                if (($this.r -gt 0) -and (-not $currCell.Walls.N)) {
                    $this.r--
                }
            }
            $this.DOWN {
                if (($this.r -lt ($this.Maze.Height - 1)) -and (-not $currCell.Walls.S)) {
                    $this.r++
                }
            }
            $this.LEFT {
                if (($this.c -gt 0) -and (-not $currCell.Walls.W)) {
                    $this.c--
                }
            }
            $this.RIGHT {
                if (($this.c -lt ($this.Maze.Width - 1)) -and (-not $currCell.Walls.E)) {
                    $this.c++
                }
            }

        }

    }


}