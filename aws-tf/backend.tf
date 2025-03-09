terraform { 
  cloud { 
    
    organization = "james-leatherman" 

    workspaces { 
      name = "ecs" 
    } 
  } 
}