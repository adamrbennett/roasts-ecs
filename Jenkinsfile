node {
  checkout scm
  stage('Deploy') {
    def service_name = "roasts-${VERSION}"
    def exists = sh script: "aws ecs describe-services --cluster ${ECS_CLUSTER} --services ${service_name} | jq -je '.services | .[0] | .serviceArn'", returnStatus: true

    if (exists == 0) {
      print "Service exists, updating"
    } else {
      print "Creating new service"
      def revision = sh script: "aws ecs register-task-definition --cli-input-json file://ecs-task-definition.json --profile ps_free | jq -j '.taskDefinition.revision'", returnStdout: true
      def target_group_arn = sh script: "aws elbv2 create-target-group --name sfiip-ecs-roasts-${env.BUILD_NUMBER} --protocol HTTP --port 80 --vpc-id ${VPC_ID} --profile ps_free | jq -j '.TargetGroups | .[0] | .TargetGroupArn'", returnStdout: true
      sh "aws elbv2 create-rule --profile ps_free --listener-arn ${ALB_LISTENER_ARN} --conditions Field=host-header,Values=roasts-${env.BUILD_NUMBER}.${DOMAIN} --priority ${PRIORITY} --actions Type=forward,TargetGroupArn=${target_group_arn}"
      sh "aws ecs create-service --profile ps_free --cluster ${ECS_CLUSTER} --service-name roasts-${env.BUILD_NUMBER} --task-definition roasts:${revision} --desired-count ${DESIRED_COUNT} --role ${ECS_SERVICE_ROLE_ARN} --load-balancers targetGroupArn=${target_group_arn},containerName=roasts,containerPort=80"
    }
  }
}
