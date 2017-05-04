node {
  checkout scm
  stage('Deploy') {
    // def revision = sh script: "aws ecs register-task-definition --cli-input-json file://ecs-task-definition.json --profile ps_free | jq -r '.taskDefinition.revision'", returnStdout: true

    sh "aws ecs register-task-definition --cli-input-json file://ecs-task-definition.json --profile ps_free"
    def target_group_arn = sh script: "aws elbv2 create-target-group --name sfiip-ecs-roasts-${env.BUILD_NUMBER} --protocol HTTP --port 80 --vpc-id ${VPC_ID} --profile ps_free | jq -r '.TargetGroups | .[0] | .TargetGroupArn'", returnStdout: true
    sh "aws elbv2 create-rule --listener-arn ${ALB_LISTENER_ARN} --conditions Field=host-header,Values=roasts-${env.BUILD_NUMBER}.${DOMAIN} --priority 100 --actions Type=forward,TargetGroupArn=${target_group_arn} --profile ps_free"
  }
}
