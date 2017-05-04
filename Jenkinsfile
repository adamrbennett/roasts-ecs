node {
  checkout scm
  stage('Deploy') {
    def revision = sh script: "aws ecs register-task-definition --cli-input-json file://ecs-task-definition.json --profile ps_free | jq -r '.taskDefinition.revision'", returnStdout: true
    print revision
  }
}
