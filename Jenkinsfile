pipeline {
    agent any

    environment {
        AWS_REGION       = 'ap-south-1'
        SECRET_NAME      = 'todo/app/credentials/2'
        JFROG_URL        = 'http://10.48.17.203:32082'
        JFROG_REPO       = 'todo-libs-release'
        ARTIFACT_VERSION = "1.0.${BUILD_NUMBER}"
        SONAR_HOST       = 'http://10.48.17.203:32000'
        BACKEND_DIR      = '/home/ubuntu/todo-api'
        FRONTEND_DIR     = '/home/ubuntu/todo-ui'
        JAVA_HOME        = '/usr/lib/jvm/java-11-openjdk-amd64'
        PATH             = "/usr/lib/jvm/java-11-openjdk-amd64/bin:/usr/local/bin:/usr/bin:/bin:${env.PATH}"
    }

    stages {

        stage('Fetch Secrets') {
            steps {
                script {
                    def secret = sh(
                        script: '/usr/local/bin/aws secretsmanager get-secret-value --secret-id todo/app/credentials/2 --region ap-south-1 --query SecretString --output text',
                        returnStdout: true
                    ).trim()

                    def json = readJSON text: secret

                    env.MONGO_USER     = json.MONGO_USER
                    env.MONGO_PASSWORD = json.MONGO_PASSWORD
                    env.JFROG_USER     = json.JFROG_USER
                    env.JFROG_PASSWORD = json.JFROG_PASSWORD
                    env.JFROG_TOKEN    = json.JFROG_TOKEN
                    env.SONAR_TOKEN    = json.SONAR_TOKEN
                }
            }
        }

        stage('Build') {
            steps {
                sh '''
                    echo "Using Java version:"
                    java -version
                    cd ${BACKEND_DIR}
                    mvn clean package -DskipTests
                '''
            }
        }

        // Skip Spring Boot integration tests, only run unit tests
        stage('Test') {
            steps {
                timeout(time: 3, unit: 'MINUTES') {
                    sh '''
                        cd ${BACKEND_DIR}
                        mvn test \
                            -Dspring.main.web-application-type=none \
                            -Dspring.autoconfigure.exclude=org.springframework.boot.autoconfigure.mongo.MongoAutoConfiguration,org.springframework.boot.autoconfigure.data.mongo.MongoDataAutoConfiguration \
                            -Dmaven.test.failure.ignore=true
                    '''
                }
            }
            post {
                always {
                    junit allowEmptyResults: true,
                          testResults: "${BACKEND_DIR}/target/surefire-reports/*.xml"
                }
            }
        }

        stage('SonarQube Analysis') {
            steps {
                sh '''
                    cd ${BACKEND_DIR}
                    mvn clean verify org.sonarsource.scanner.maven:sonar-maven-plugin:sonar \
                        -Dspring.main.web-application-type=none \
                        -Dspring.autoconfigure.exclude=org.springframework.boot.autoconfigure.mongo.MongoAutoConfiguration,org.springframework.boot.autoconfigure.data.mongo.MongoDataAutoConfiguration \
                        -Dsonar.projectKey=todo-api \
                        -Dsonar.projectName='todo-api' \
                        -Dsonar.host.url=${SONAR_HOST} \
                        -Dsonar.token=${SONAR_TOKEN}
                '''
            }
        }

        stage('Quality Gate') {
            steps {
                timeout(time: 5, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage('Push to JFrog') {
            steps {
                sh '''
                    JAR_FILE=$(find ${BACKEND_DIR}/target -name "*.jar" ! -name "*sources*" | head -1)
                    echo "Pushing ${JAR_FILE} as version ${ARTIFACT_VERSION}..."
                    curl -u ${JFROG_USER}:${JFROG_TOKEN} \
                        -T ${JAR_FILE} \
                        "${JFROG_URL}/artifactory/${JFROG_REPO}/com/todo/todo-api/${ARTIFACT_VERSION}/todo-api-${ARTIFACT_VERSION}.jar"
                    echo "Pushed: todo-api-${ARTIFACT_VERSION}.jar"
                '''
            }
        }

        stage('Deploy Backend') {
            steps {
                sh '''
                    curl -u ${JFROG_USER}:${JFROG_TOKEN} \
                        -o ${BACKEND_DIR}/todo-api-${ARTIFACT_VERSION}.jar \
                        "${JFROG_URL}/artifactory/${JFROG_REPO}/com/todo/todo-api/${ARTIFACT_VERSION}/todo-api-${ARTIFACT_VERSION}.jar"

                    pkill -f "todo-api" || true
                    sleep 3

                    nohup /usr/lib/jvm/java-11-openjdk-amd64/bin/java \
                        -jar ${BACKEND_DIR}/todo-api-${ARTIFACT_VERSION}.jar \
                        --spring.data.mongodb.username=${MONGO_USER} \
                        --spring.data.mongodb.password=${MONGO_PASSWORD} \
                        > ${BACKEND_DIR}/app.log 2>&1 &

                    echo "Deployed version: ${ARTIFACT_VERSION}"
                '''
            }
        }

        stage('Deploy Frontend') {
            steps {
                sh '''
                    export NVM_DIR="/home/ubuntu/.nvm"
                    source "$NVM_DIR/nvm.sh"
                    pkill -f "react-scripts start" || true
                    sleep 3
                    cd ${FRONTEND_DIR}
                    bash env.sh
                    nohup npm start > ${FRONTEND_DIR}/ui.log 2>&1 &
                    echo "Frontend deployed"
                '''
            }
        }
    }

    post {
        success {
            echo "Pipeline SUCCESS - version ${ARTIFACT_VERSION} deployed"
        }
        failure {
            echo "Pipeline FAILED - check logs"
        }
    }
}