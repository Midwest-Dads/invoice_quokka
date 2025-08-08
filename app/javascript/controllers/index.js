// Import and register all your controllers for Vite
import { application } from "./application"

// Import controllers
import HelloController from "./hello_controller"

// Register controllers
application.register("hello", HelloController)
