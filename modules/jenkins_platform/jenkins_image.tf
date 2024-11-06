data "aws_ecr_authorization_token" "token" {}

locals {
  ecr_endpoint = split("/", aws_ecr_repository.jenkins_controller.repository_url)[0]
}


resource "aws_ecr_repository" "jenkins_controller" {
  name                 =  var.jenkins_ecr_repository_name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration  {
      scan_on_push = true
  }

}

data "template_file" jenkins_configuration_def {

  template = file("${path.module}/docker/files/jenkins.yaml.tpl")
  

  vars = {
    ADMIN_PWD = "jenkinsadmin123"
    ecs_cluster_fargate       = aws_ecs_cluster.jenkins_controller.arn
    ecs_cluster_fargate_spot  = aws_ecs_cluster.jenkins_agents.arn
    cluster_region            = local.region
    jenkins_cloud_map_name    = "controller.${var.name_prefix}"
    jenkins_controller_port       = var.jenkins_controller_port
    jnlp_port                 = var.jenkins_jnlp_port
    agent_security_groups     = aws_security_group.jenkins_controller_security_group.id
    execution_role_arn        = aws_iam_role.ecs_execution_role.arn
    subnets                   = join(",", var.jenkins_controller_subnet_ids)
  }
}

resource "null_resource" "render_template" {
  triggers = {
    src_hash   = file("${path.module}/docker/files/jenkins.yaml.tpl")
    always_run = timestamp()
  }
  depends_on = [data.template_file.jenkins_configuration_def]

  provisioner "local-exec" {
    command = <<-EOF
      echo "${data.template_file.jenkins_configuration_def.rendered}" > ${path.module}/docker/files/jenkins.yaml
    EOF
  }
}




# resource "null_resource" "build_docker_image" {
#   triggers = {
#     src_hash = file("${path.module}/docker/files/jenkins.yaml.tpl")
#     always_run = timestamp()
#   }
#   depends_on = [null_resource.render_template]

#   provisioner "local-exec" {
#     command = <<-EOF
#       echo ${data.aws_ecr_authorization_token.token.password} | docker login -u AWS --password-stdin ${local.ecr_endpoint} && \
#       docker build -t ${aws_ecr_repository.jenkins_controller.repository_url}:latest ${path.module}/docker/ && \
#       docker push ${aws_ecr_repository.jenkins_controller.repository_url}:latest
#     EOF
#   }
# }

resource "null_resource" "build_docker_image" {
  triggers = {
    src_hash = file("${path.module}/docker/files/jenkins.yaml.tpl")
    always_run = timestamp()
  }
  depends_on = [null_resource.render_template]

  provisioner "local-exec" {
    command = <<-EOF
      aws ecr get-login-password --region ${var.region} | docker login -u AWS --password-stdin ${local.ecr_endpoint}
      docker build -t ${aws_ecr_repository.jenkins_controller.repository_url}:latest ${path.module}/docker/
      docker push ${aws_ecr_repository.jenkins_controller.repository_url}:latest
    EOF
}

}

# Define variables as needed
variable "region" {
  default = "ap-south-1"  # or any other region you are using
}

locals {
  #ecr_endpoint = "138742408051.dkr.ecr.${var.region}.amazonaws.com"
  repo_uri     = "${local.ecr_endpoint}/serverless-jenkins-controller"
}


