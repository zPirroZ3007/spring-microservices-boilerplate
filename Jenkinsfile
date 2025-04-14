pipeline {

    agent { label 'ec2' }

    environment {
        NAME = "${currentBuild.fullProjectName.split('/')[1]}"

        GHCR = credentials('ghcr')

        VERSION = "${GIT_BRANCH}-1.0.${BUILD_NUMBER}"

        AWS = credentials('aws')
        AWS_ACCESS_KEY_ID = "${AWS_USR}"
        AWS_SECRET_ACCESS_KEY = "${AWS_PSW}"
        AWS_DEFAULT_REGION = 'eu-south-1'

        S3_BUCKET = 'caches.yourorganization.com'
        S3_CACHE_PATH = "gradle-cache/${currentBuild.fullProjectName}/gradle_cache.zip"
        CACHE_DIR = "${env.WORKSPACE}/caches/gradle_cache"
        CACHE_ZIP = 'gradle_cache.zip'

        TF_IN_AUTOMATION = '1'
        TF_VAR_git_token = "${GHCR_PSW}"
        TF_VAR_git_user = "${GHCR_USR}"
        TF_VAR_image_version = "${VERSION}"
        TF_VAR_prefix = "${NAME}"

        DEPLOY = false
    }

    stages {
        stage('Restore Gradle Cache') {
            steps {
                script {
                    docker.image('320362050948.dkr.ecr.eu-south-1.amazonaws.com/awscli').inside {
                        sh '''
                            mkdir -p ${CACHE_DIR}
                            aws s3 cp s3://${S3_BUCKET}/${S3_CACHE_PATH} ${CACHE_ZIP} || echo "No cache found, proceeding without it."
                            if [ -f ${CACHE_ZIP} ]; then
                                unzip -o ${CACHE_ZIP} -d ${CACHE_DIR}/
                                rm ${CACHE_ZIP}
                                    find ${CACHE_DIR} -name "*.lock" -delete
                            fi
                        '''
                    }
                }
            }
        }
        stage('Test') {
            steps {
                script {
                    docker.image('gradle:8.6.0-jdk17').inside("--privileged " +
                            "--mount type=bind,source=/var/run/docker.sock,target=/var/run/docker.sock" +
                            " --mount type=bind,source=${CACHE_DIR},target=/home/gradle/.gradle") {
                        sh 'gradle --no-daemon --project-cache-dir /home/gradle/.gradle_cache :test'
                    }
                }
            }
        }
        stage('Build') {
            steps {
                script {
                    docker.image('gradle:8.6.0-jdk17').inside("--privileged " +
                            "--mount type=bind,source=/var/run/docker.sock,target=/var/run/docker.sock" +
                            " --mount type=bind,source=${CACHE_DIR},target=/home/gradle/.gradle") {
                        sh """
                        rm -f src/main/resources/openapi.json
                        gradle --no-daemon --project-cache-dir /home/gradle/.gradle_cache :generateOpenApiDocs -x test
                        gradle --no-daemon --project-cache-dir /home/gradle/.gradle_cache :openApiGenerate :build -x test
                        """

                        if (fileExists("./${NAME}-module/build.gradle.kts"))
                            sh "gradle ${NAME}-module:generateJooq ${NAME}-module:build --no-daemon"
                    }
                }
            }
        }
        stage('Build and Push Docker Image') {
            steps {
                script {
                    docker.image('docker:latest').inside('--privileged -v /var/run/docker.sock:/var/run/docker.sock') {
                        sh """
                        docker login ghcr.io -u ${GHCR_USR} -p ${GHCR_PSW}
                        docker context create jenkins
                        docker buildx create --use jenkins --platform=linux/arm64,linux/amd64 --name multi-platform-builder
                        docker buildx build --push --platform linux/amd64,linux/arm64 -t ghcr.io/org/${NAME}:${VERSION} .
                        """
                    }
                }
            }
        }
        stage('Deploy') {
            when {
                branch 'master'
                environment name: 'DEPLOY', value: 'true'
            }
            steps {
                script {
                    docker.image('gradle:8.6.0-jdk17').inside("--mount type=bind,source=${CACHE_DIR},target=/home/gradle/.gradle") {
                        sh """
                        cp init-client.gradle build/client/init-client.gradle
                        cd build/client && chmod +x gradlew && ./gradlew --init-script init-client.gradle publish && cd -
                        """

                        if (fileExists("./${NAME}-module/build.gradle.kts"))
                            sh '''
                            curl -F "key=${DEPLOY_KEY}" -F "file=@${DEPLOY_FILE}" -F "destination=${DEPLOY_DEST}" "${DEPLOY_SERVER}" | grep 'successo' &> /dev/null
                            if [ $? -ne 0 ]; then
                                exit 1
                            fi
                            '''
                    }

                    docker.image('320362050948.dkr.ecr.eu-south-1.amazonaws.com/terraform').inside {
                        sh """    
                            set -e  # Stop execution if any command fails
                    
                            LISTENER_ARN=""
                    
                            echo "Fetching existing listener rules..."
                            
                            # Fetch listener rules from AWS CLI
                            PRIORITIES=\$(aws elbv2 describe-rules --listener-arn "\$LISTENER_ARN" --query "Rules[*].Priority" --output text | tr '\\t' '\\n' | grep -Eo '[0-9]+' | sort -n || true)
                    
                            # Check if there are any existing priorities
                            if [ -z "\$PRIORITIES" ]; then
                                NEXT_PRIORITY=1  # If no rules exist, start from priority 1
                            else
                                NEXT_PRIORITY=\$((\$(echo "\$PRIORITIES" | tail -n1) + 1))
                            fi
                    
                            echo "Next available priority: \$NEXT_PRIORITY"
                    
                            # Terraform Commands
                            terraform -chdir=./infra init -input=false -backend-config="key=terraform-${NAME}.tfstate"
                            terraform -chdir=./infra apply -input=false -auto-approve -var="rule_priority=\$NEXT_PRIORITY"
                        """
                    }
                }
            }
        }

        stage('Save Gradle Cache') {
            steps {
                script {
                    docker.image('320362050948.dkr.ecr.eu-south-1.amazonaws.com/awscli').inside {
                        sh '''
                            cd ${CACHE_DIR}
                            zip -r ${CACHE_ZIP} *
                            aws s3 cp ${CACHE_ZIP} s3://${S3_BUCKET}/${S3_CACHE_PATH} --only-show-errors
                            rm ${CACHE_ZIP}
                        '''
                    }
                }
            }
        }
    }

    post {
        always {
            archiveArtifacts artifacts: 'build/reports/**', fingerprint: true
        }
    }
}
