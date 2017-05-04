node {
  checkout scm
  stage('Deploy') {
    sh "aws ecs register-task-definition --cli-input-json file://ecs-task-definition.json --profile ps_free"
  }
}
