########## GAME ##########
Write-Output "Starting the game!"
$maze = [Maze]::new()
# Write-Output $maze.Grid[0,0]
# Write-Output "Walls: " $maze.Grid[0,0].Walls
# Write-Output "North: " $maze.Grid[0,0].Walls.N
# Write-Output "East: " $maze.Grid[0,0].Walls.E
# Write-Output "West: " $maze.Grid[0,0].Walls.S
# Write-Output "South: " $maze.Grid[0,0].Walls.W
# Write-Output $maze.GetStringRep()
# Write-Output $maze.Grid[1,1]
# Write-Output "Neighbour: " $maze.PickRandomUnvisitedNeighbourOf(($maze.Grid[1,1]))

Write-Output "Visitations: " $maze.PartitionGrid()
Write-Output $maze.GetStringRep()

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
            $rep += '_'
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

    Maze() {
        $this.Width = 10
        $this.Height = 10

        Write-Output "Generating the maze!"
        $this.GenerateMaze()
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