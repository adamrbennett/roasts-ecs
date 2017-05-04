node {
  stage('Deploy') {
    sh "aws ecr get-login --profile ps_free | sh"
    sh "docker pull ${DOCKER_IMAGE}"
  }
}
