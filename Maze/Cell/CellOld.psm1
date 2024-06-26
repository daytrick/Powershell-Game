class Cell {

    # Record where it is on the grid
    [int] $r
    [int] $c

    # Record info about neighbours
    [Boolean[]] $Walls
    [Boolean]   $Visited
    [Cell]      $PrevCell


    # Constructor
    Cell([int] $r, [int] $c) {
        $this.r = $r
        $this.c = $c
        $this.Walls = @{N = $true; E = $true; S = $true; W = $true}
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

function GenerateCell([int] $r, [int] $c) {
    return [Cell]::new($r, $c)
}

Export-ModuleMember -Function GenerateCell