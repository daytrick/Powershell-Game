# Import-Module ./Maze/Cell/Cell.psm1

. ./Cell/Cell.ps1

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
                $cell = GenerateCell($r, $c)
                $this.Grid[$r,$c] = $cell
            }
        }

    }


    [void] PartitionGrid() {
        
    }

    [void] Draw() {

        $topBorder = '_'
        for ($c = 0; $c -lt $this.Width; $c++) {
            $topBorder += "__"
        }
        Write-Output $topBorder

        for ($r = 0; $r -lt $this.Height; $r++) {
            $this.DrawRow($r)
        }

    }

    [void] DrawRow([int] $r) {

        $row = '|'

        for ($c = 0; $c -lt $this.Width; $c++) {
            $row += $this.Grid[$r][$c]::GetStringRep()
        }

        Write-Output $row

    }

}


function GenerateMaze() {
    return [Maze]::new()
}


Export-ModuleMember -Function GenerateMaze