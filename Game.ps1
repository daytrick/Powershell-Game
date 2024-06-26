########## GAME ##########
Write-Output "Starting the game!"
$maze = [Maze]::new()
# Write-Output $maze.Grid[0,0]
# Write-Output "Walls: " $maze.Grid[0,0].Walls
# Write-Output "North: " $maze.Grid[0,0].Walls.N
# Write-Output "East: " $maze.Grid[0,0].Walls.E
# Write-Output "West: " $maze.Grid[0,0].Walls.S
# Write-Output "South: " $maze.Grid[0,0].Walls.W
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
            # $rep += ' '
            $rep += '1' + $this.Walls.S + '2'
        }

        if ($this.Walls.E) {
            $rep += '|'
        }
        else {
            # $rep += ' '
            $rep += '1' + $this.Walls.S + '2'
        }

        return $rep

    }

}

########## MAZE ##########

class Maze {

    [int] $Width
    [int] $Height

    [Object[,]] $Grid

    Maze() {
        $this.Width = 10
        $this.Height = 10

        Write-Output "Generating the maze!"
        $this.GenerateMaze()
    }

    [void] GenerateMaze() {

        Write-Output "In GenerateMaze!"

        $this.Grid = New-Object 'Object[,]' $this.Height,$this.Width

        for ([int] $r = 0; $r -lt $this.Height; $r++) {
            for ([int] $c = 0; $c -lt $this.Width; $c++) {
                $this.Grid[$r,$c] = [Cell]::new($r, $c)
            }
        }

    }


    [void] PartitionGrid() {
        
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
            $row += $this.Grid[$r,$c].GetStringRep()
        }

        return $row

    }

}