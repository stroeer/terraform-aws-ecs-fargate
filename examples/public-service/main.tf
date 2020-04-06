locals {
  service_name = "httpd"
}

module "service" {
  source = "../../"

  alb_listener_priority      = 777
  assign_public_ip           = true
  cluster_id                 = "k8"
  container_port             = 80
  create_deployment_pipeline = false
  create_log_streaming       = false
  desired_count              = 1
  health_check_endpoint      = "/"
  service_name               = "httpd"
  container_definitions      = <<DOC
[
  {
    "command": [
      "/bin/sh -c \"echo '<html> <head> <title>Hello from httpd service</title> <style>body {margin-top: 40px; background-color: #333;} </style> </head><body> <div style=color:white;text-align:center> <h1>Amazon ECS Sample App</h1> <h2>Congratulations!</h2> <p>Your application is now running on a container in Amazon ECS.</p> </div></body></html>' >  /usr/local/apache2/htdocs/index.html && httpd-foreground\""
    ],
    "cpu": 256,
    "entryPoint": [
      "sh",
      "-c"
    ],
    "essential": true,
    "image": "httpd:2.4",
    "memory": 512,
    "name": "${local.service_name}",
    "portMappings": [ 
        { 
            "containerPort": 80,
            "hostPort": 80,
            "protocol": "tcp"
        }
    ]
  }
]
DOC

  ecr = {
    image_tag_mutability = "IMMUTABLE"
    image_scanning_configuration = {
      scan_on_push = true
    }
  }
}
