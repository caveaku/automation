pipeline {
    agent any

    environment {
        AWS_REGION     = 'us-east-1'
        // Terraform is in the repo root, not in an "automation" directory
        TF_WORKING_DIR = '.'
    }

    options {
        timestamps()
        disableConcurrentBuilds()
    }

    triggers {
        // For a Multibranch Pipeline, GitHub webhook is enough; this trigger is optional.
        pollSCM('@daily')
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Terraform Init / Validate / Plan') {
            steps {
                withCredentials([
                    string(credentialsId: 'aws_access_key', variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'aws_secret_key', variable: 'AWS_SECRET_ACCESS_KEY')
                ]) {
                    dir("${TF_WORKING_DIR}") {
                        sh '''
                            export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
                            export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
                            export AWS_DEFAULT_REGION=${AWS_REGION}

                            echo ">>> Verifying AWS credentials..."
                            aws sts get-caller-identity || exit 1

                            echo ">>> Running terraform init..."
                            terraform init

                            echo ">>> Running terraform validate..."
                            terraform validate

                            echo ">>> Running terraform plan..."
                            terraform plan -out=tfplan
                        '''
                    }
                }
            }
        }

        stage('Terraform Apply') {
            // Only actually deploy from the main branch
            when {
                branch 'main'
            }
            steps {
                withCredentials([
                    string(credentialsId: 'aws_access_key', variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'aws_secret_key', variable: 'AWS_SECRET_ACCESS_KEY')
                ]) {
                    dir("${TF_WORKING_DIR}") {
                        sh '''
                            export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
                            export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
                            export AWS_DEFAULT_REGION=${AWS_REGION}

                            echo ">>> Verifying AWS credentials before apply..."
                            aws sts get-caller-identity || exit 1

                            echo ">>> Running terraform apply using saved plan (tfplan)..."
                            terraform apply -auto-approve tfplan
                        '''
                    }
                }
            }
        }
    }

    post {
        always {
            echo "Pipeline finished."
        }
        success {
            echo "Terraform apply completed successfully."
        }
        failure {
            echo "Terraform pipeline failed!"
        }
    }
}
