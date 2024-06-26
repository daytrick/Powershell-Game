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

# Write-Output "\n"
Write-Output "Visitations: " $maze.PartitionGrid()
Write-Output $maze.GetStringRep()

########## CELL ##########

class Cell {

    # Record where it is on the grid
    [int] $r
    [int] $c

    # Record info about neighbours
    [Hashtable] $Walls
    [Boolean]   $Visited
    [Cell]      $PrevCell


    # Constructor
    Cell([int] $r, [int] $c) {
        $this.r = $r
        $this.c = $c
        $this.Walls = @{N = $true; E = $true; S = $true; W = $true}
        Write-Output "walls: " $this.Walls
        $this.Visited = $false
        $this.PrevCell = $null
    }

    # Visit the cell
    [Boolean] Visit([Cell] $currentCell) {

        # Don't visit if already been
        if ($this.Visited) {
            return $false
        }
        
        # Otherwise, visit the cell
        $this.Visited = $true

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

class Maze {

    [int] $Width
    [int] $Height

    [Cell[,]] $Grid

    Maze() {
        $this.Width = 5
        $this.Height = 5

        Write-Output "Generating the maze!"
        $this.GenerateMaze()
    }

    [void] GenerateMaze() {

        Write-Output "In GenerateMaze!"

        $this.Grid = New-Object 'Cell[,]' $this.Height,$this.Width

        for ([int] $r = 0; $r -lt $this.Height; $r++) {
            for ([int] $c = 0; $c -lt $this.Width; $c++) {
                $this.Grid[$c, $r] = [Cell]::new($c, $r)
            }
        }

    }


    [int16] PartitionGrid() {

        # Choose random initial cell
        $r = Get-Random -Maximum $this.Height
        $c = Get-Random -Maximum $this.Width
        $start = $this.Grid[$c, $r]
        $start.Visit($null)

        # Create stack
        $stack = New-Object System.Collections.Stack
        $stack.Push($start)

        $visitations = 0
        while ($stack.Count -gt 0) {
            $currCell = $stack.Pop()

            # Pick random neighbour to visit
            $neighbour = $this.PickRandomUnvisitedNeighbourOf($currCell)
            if (($null -ne $neighbour) -and (-not $neighbour.Visited)) {
                $stack.Push($currCell)
                $neighbour.Visit($currCell)
                $stack.Push($neighbour)
                $visitations++
            }

            # # Pick random neighbour to visit
            # $neighbour = $this.PickRandomUnvisitedNeighbourOf($currCell)
            # $count = 0
            # while ($neighbour) {
            #     if (-not $neighbour.Visited) {
            #         $stack.Push($currCell)
            #         $neighbour.Visit($currCell)
            #         $stack.Push($neighbour)
            #         $currCell = $neighbour
            #         $visitations++
            #     }
            #     $neighbour = $this.PickRandomUnvisitedNeighbourOf($currCell)
            #     $count++
            #     Write-Output $count
            # }
            

        }

        return $visitations
        
    }

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

    [String] GetRowStringRep([int] $r) {

        $row = '|'

        for ($c = 0; $c -lt $this.Width; $c++) {
            $row += $this.Grid[$c,$r].GetStringRep()
        }

        return $row

    }

}