node {
  checkout scm
  stage('Deploy') {
    def revision = sh script: "aws ecs register-task-definition --cli-input-json file://ecs-task-definition.json --profile ps_free | jq -r '.taskDefinition.revision'", returnStdout: true
    sh "aws elbv2 create-target-group --name sfiip-ecs-roasts-${env.BUILD_NUMBER} --protocol HTTP --port 80 --vpc-id ${VPC_ID} --profile ps_free"
  }
}
