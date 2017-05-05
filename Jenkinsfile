node {
  // checkout from scm into our workspace
  checkout scm

  stage('Deploy') {
    def service_name = "roasts-${VERSION}"

    // check if the service already exists
    def exists = sh script: "aws ecs describe-services --profile ps_free --cluster ${ECS_CLUSTER} --services ${service_name} | jq -je '.services | .[0] | select(.status == \"ACTIVE\") | .serviceArn'", returnStatus: true

    // create a new task definition
    // def revision = sh script: "aws ecs register-task-definition --cli-input-json file://ecs-task-definition.json --profile ps_free | jq -j '.taskDefinition.revision'", returnStdout: true
    def revision = sh script: '''
      aws ecs register-task-definition --profile ps_free --family roasts --container-definitions <<EOF | jq -j '.taskDefinition.revision'
        [
          {
            "cpu": 128,
            "environment": [{
              "name": "APP_PORT",
              "value": "80"
            }],
            "portMappings": [
              {
                "hostPort": 0,
                "containerPort": 80,
                "protocol": "tcp"
              }
            ],
            "logConfiguration": {
              "logDriver": "awslogs",
              "options": {
                "awslogs-group": "sfiip-roasts",
                "awslogs-region": "us-east-1"
              }
            },
            "essential": true,
            "image": "${DOCKER_IMAGE}",
            "memory": 128,
            "memoryReservation": 64,
            "name": "roasts"
          }
        ]
      EOF
    ''', returnStdout: true

    if (exists == 0) {
      print "Service ${service_name} already exists, updating"

      // update the service to use the new task definition
      sh "aws ecs update-service --profile ps_free --cluster sfiip --service ${service_name} --task-definition roasts:${revision}"
    } else {
      print "Creating new service: ${service_name}"

      // create the target group
      def target_group_arn = sh script: "aws elbv2 create-target-group --name sfiip-ecs-${service_name} --protocol HTTP --port 80 --vpc-id ${VPC_ID} --profile ps_free | jq -j '.TargetGroups | .[0] | .TargetGroupArn'", returnStdout: true

      // update the target group attributes
      sh "aws elbv2 modify-target-group-attributes --profile ps_free --target-group-arn ${target_group_arn} --attributes Key=deregistration_delay.timeout_seconds,Value=60"

      // determine the new priority (max existing + 1)
      def max_priority = sh script: "aws elbv2 describe-rules --profile ps_free --listener-arn ${ALB_LISTENER_ARN} | jq -j '.Rules | sort_by(.Priority) | .[0:-1] | max_by(.Priority) | .Priority'", returnStdout: true
      def priority = 100
      if (max_priority.isNumber())
        priority = (max_priority as Integer) + 1

      // create the ALB listener rule
      sh "aws elbv2 create-rule --profile ps_free --listener-arn ${ALB_LISTENER_ARN} --conditions Field=host-header,Values=${service_name}.${DOMAIN} --priority ${priority} --actions Type=forward,TargetGroupArn=${target_group_arn}"

      // create the new service
      sh "aws ecs create-service --profile ps_free --cluster ${ECS_CLUSTER} --service-name ${service_name} --task-definition roasts:${revision} --desired-count ${DESIRED_COUNT} --role ${ECS_SERVICE_ROLE_ARN} --load-balancers targetGroupArn=${target_group_arn},containerName=roasts,containerPort=80"
    }
  }
}
