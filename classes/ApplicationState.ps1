if ('ApplicationState' -as [Type]) {
  return
}
Add-Type -TypeDefinition @"
    using System;
    
    public class ApplicationState {
    
        public string Id;
        public string Name;
        public bool Continue;
        public object Data;
        
        public ApplicationState() {
            this.Id = Guid.NewGuid().ToString();
            this.Name = "Application Name";
        }
        public ApplicationState(string name) {
            this.Id = Guid.NewGuid().ToString();
            this.Name = name;
        }
    }
"@