pipeline {
    agent any

    // 👇 This creates a dropdown parameter in the Jenkins UI
    parameters {
        choice(
            name: 'TF_ACTION',
            choices: ['plan', 'apply', 'destroy'],
            description: 'Select which Terraform action to run'
        )
    }

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

        // Always run init + validate (safe for all actions)
        stage('Terraform Init / Validate') {
            steps {
                withCredentials([
                    string(credentialsId: 'aws_access_key',  variable: 'AWS_ACCESS_KEY_ID'),
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
                        '''
                    }
                }
            }
        }

        // Run plan if TF_ACTION is "plan" or "apply"
        stage('Terraform Plan') {
            when {
                anyOf {
                    expression { params.TF_ACTION == 'plan' }
                    expression { params.TF_ACTION == 'apply' }
                }
            }
            steps {
                withCredentials([
                    string(credentialsId: 'aws_access_key',  variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'aws_secret_key', variable: 'AWS_SECRET_ACCESS_KEY')
                ]) {
                    dir("${TF_WORKING_DIR}") {
                        sh '''
                            export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
                            export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
                            export AWS_DEFAULT_REGION=${AWS_REGION}

                            echo ">>> Running terraform plan..."
                            terraform plan -out=tfplan
                        '''
                    }
                }
            }
        }

        // Only run apply when TF_ACTION == "apply"
        stage('Terraform Apply') {
            when {
                expression { params.TF_ACTION == 'apply' }
            }
            steps {
                withCredentials([
                    string(credentialsId: 'aws_access_key',  variable: 'AWS_ACCESS_KEY_ID'),
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

        // Only run destroy when TF_ACTION == "destroy"
        stage('Terraform Destroy') {
            when {
                expression { params.TF_ACTION == 'destroy' }
            }
            steps {
                withCredentials([
                    string(credentialsId: 'aws_access_key',  variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'aws_secret_key', variable: 'AWS_SECRET_ACCESS_KEY')
                ]) {
                    dir("${TF_WORKING_DIR}") {
                        sh '''
                            export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
                            export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
                            export AWS_DEFAULT_REGION=${AWS_REGION}

                            echo ">>> Verifying AWS credentials before destroy..."
                            aws sts get-caller-identity || exit 1

                            echo ">>> Running terraform destroy..."
                            terraform destroy -auto-approve
                        '''
                    }
                }
            }
        }
    }

    post {
        always {
            echo "Pipeline finished. TF_ACTION selected: ${params.TF_ACTION}"
        }
        success {
            echo "Terraform ${params.TF_ACTION} completed successfully."
        }
        failure {
            echo "Terraform pipeline failed during ${params.TF_ACTION}!"
        }
    }
}
