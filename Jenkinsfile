def apply = false
def exitCode = 0

node {

  stage('Checkout') {
    checkout scm
  }

  // get terraform and add it to the path
  def tfHome = tool name: 'Terraform', type: 'com.cloudbees.jenkins.plugins.customtools.CustomTool'
  env.PATH = "${tfHome}:${env.PATH}"

  // show colored output
  wrap([$class: 'AnsiColorBuildWrapper', colorMapName: 'xterm']) {

    stage('Plan') {

      sh "terraform --version"

      // clean state every build
      if (fileExists(".terraform/terraform.tfstate")) {
        sh "rm -rf .terraform/terraform.tfstate"
      }

      // initialize the terraform remote s3 backend
      sh "terraform init -backend-config 'key=dev/services/roasts-${VERSION}.tfstate'"

      // download modules
      sh "terraform get"

      // plan and save proposed changes
      exitCode = sh script: "set +e; terraform plan -var version=${VERSION} -out=plan.out -detailed-exitcode", returnStatus: true
      echo "Terraform Plan Exit Code: ${exitCode}"

      // 2 = changes required
      if (exitCode == 2) {

        // stash the planned changes
        stash name: "plan", includes: "plan.out"

      }
    }
  }
}

// 0 = nothing to change
if (exitCode == 0) {
  currentBuild.result = 'SUCCESS'
}

// 1 = error planning
if (exitCode == 1) {
  currentBuild.result = 'FAILURE'
}

// 2 = changes required
if (exitCode == 2) {
  // wait for input
  try {
    input message: 'Apply Plan?', ok: 'Apply'
    apply = true
  } catch (err) {
    apply = false
    currentBuild.result = 'ABORTED'
  }
}

if (apply) {

  node {

    // show colored output
    wrap([$class: 'AnsiColorBuildWrapper', colorMapName: 'xterm']) {

      stage ('Apply') {

        // get our planned changes
        unstash 'plan'

        // apply changes
        def applyExitCode = sh script: 'set +e; terraform apply plan.out', returnStatus: true
        if (applyExitCode == 0) {
            echo "Changes applied"
        } else {
            currentBuild.result = 'FAILURE'
        }
      }
    }
  }
}
