# Need to parameterize class with "id" in order to re-load class during local testing
$Id = if ($Env:ProjectName -eq 'pwsh-prelude' -and $Env:BuildSystem -eq 'Unknown') { 'Test' } else { '' }
$TypeDefinition = @"
    using System;

    public class Edge${Id} {

        public int Id;
        public string To;
        public string From;
        public int Weight = 1;

        public Edge${Id}() {
            this.Id = 43;
        }
    }
    public class Graph${Id} {

        public int Id;

        public Graph${Id}() {
            this.Id = 42;
        }
    }
"@
if ("Graph${Id}" -as [Type]) {
  return
} else {
  Add-Type -TypeDefinition $TypeDefinition
  if ($Env:BuildSystem -eq 'Travis CI') {
    $Accelerators = [PowerShell].Assembly.GetType('System.Management.Automation.TypeAccelerators')
    $Accelerators::Add('EdgeTest', 'Edge')
    $Accelerators::Add('GraphTest', 'Graph')
  }
}