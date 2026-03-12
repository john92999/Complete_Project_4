pipeline{
    agent any
    environment{
        AWS_REGION = "ap-south-1"
        SECRET_NAME = "todo/app/credentials/2"
        JFROG_URL = "http://10.48.17.40:30465"
        JFROG_REPO = "todo-libs-release"
        ARTIFACT_VERSION = "1.0.${BUILD_NUMBER}"
        SONAR_HOST = "http://10.48.17.40:32000"
        BACKEND_DIR = "/home/ubuntu1/todo-api"
        FRONTEND_DIR = "/home/ubuntu1/todo-ui"
        JAVA_HOME = "/usr/lib/jvm/java-11-openjdk-amd64"
        PATH = "/usr/lib/jvm/java-11-openjdk-amd64/bin:/usr/local/bin:/usr/bin:/bin:${env.PATH}"
    }
    stages{
        stage ('Fetch Secrets'){
            steps{
                script{
                    def secret = sh(
                        script: '/usr/local/bin/aws secretsmanager get-secret-value --secret-id todo/app/credentials/2 --region ap-south-1 --query SecretString --output text',
                        returnStdout: true
                    ).trim()
                    
                    def json = readJSON text: secret

                    env.MONGO_USER = json.MONGO_USER
                    env.MONGO_PASSWORD = json.MONGO_PASSWORD
                    env.JFROG_USER = json.JFROG_USER
                    env.JFROG_PASSWORD = json.JFROG_PASSWORD
                    env.JFROG_TOKEN = json.JFROG_TOKEN
                    env.SONAR_TOKEN = json.SONAR_TOKEN
                    echo "Secrets fetched successfully"
                }
            }
        }
        stage('Build') {
            steps {
                sh '''
                    # Force Java 11 explicitly for this stage
                    export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
                    export PATH=$JAVA_HOME/bin:$PATH

                    echo "=== Verifying Java version (must be 11) ==="
                    java -version

                    echo "=== Starting build ==="
                    cd ${BACKEND_DIR}
                    mvn clean package -DskipTests

                    echo "=== Build output ==="
                    ls -lh ${BACKEND_DIR}/target/*.jar
                '''
            }
        }
        stage('Test') {
            steps {
                timeout(time: 3, unit: 'MINUTES') {
                    sh '''
                        export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
                        export PATH=$JAVA_HOME/bin:$PATH
                        cd ${BACKEND_DIR}
                        mvn test \
                            -Dexclude='**/TodoApplicationTests.java' \
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
        stage('SonarQube Analysis + Quality Gate') {
            steps {
                withSonarQubeEnv('sonarqube') {
                    sh '''
                        export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
                        export PATH=$JAVA_HOME/bin:$PATH
                        cd ${BACKEND_DIR}
                        mvn clean verify org.sonarsource.scanner.maven:sonar-maven-plugin:sonar \
                            -Dexclude='**/TodoApplicationTests.java' \
                            -Dmaven.test.failure.ignore=true \
                            -Dsonar.projectKey=todo-api \
                            -Dsonar.projectName='todo-api' \
                            -Dsonar.host.url=${SONAR_HOST} \
                            -Dsonar.token=${SONAR_TOKEN}
                    '''
                }
                timeout(time: 5, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }
        stage('Push the build to Jfrog'){
            steps{
                sh '''
                JAR_FILE=$(find ${BACKEND_DIR}/target -name "*.jar" ! -name "*sources*" | head -1)
                echo "Found JAR: ${JAR_FILE}"
                curl -f -u ${JFROG_USER}:${JFROG_TOKEN} \
                    -T ${JAR_FILE} \
                    "${JFROG_URL}/artifactory/${JFROG_REPO}/com/todo/todo-api/${ARTIFACT_VERSION}/todo-api-${ARTIFACT_VERSION}.jar"
                curl -s -o /dev/null -w "Upload response code: %{http_code}" \
                    -u ${JFROG_USER}:${JFROG_TOKEN} \
                    "${JFROG_URL}/artifactory/${JFROG_REPO}/com/todo/todo-api/${ARTIFACT_VERSION}/todo-api-${ARTIFACT_VERSION}.jar"
                echo "${JFROG_URL}/artifactory/${JFROG_REPO}/com/todo/todo-api/${ARTIFACT_VERSION}/todo-api-${ARTIFACT_VERSION}.jar"
                '''
            }
        }
        stage('Approval gate'){
            steps{
                timeout(time: 10, unit: 'MINUTES'){
                    input message: """
                    Deploy version ${ARTIFACT_VERSION} to server?
                    """,
                    ok: 'Yes, Deploy Now'
                }
            }
        }
        stage('Deploy Backend'){
            steps{
                sh '''
                curl -f -u ${JFROG_USER}:${JFROG_TOKEN} \
                    -o ${BACKEND_DIR}/todo-api-${ARTIFACT_VERSION}.jar \
                    "${JFROG_URL}/artifactory/${JFROG_REPO}/com/todo/todo-api/${ARTIFACT_VERSION}/todo-api-${ARTIFACT_VERSION}.jar"
                pkill -f "todo-api.*jar" || true
                sleep 3
                nohup /usr/lib/jvm/java-11-openjdk-amd64/bin/java \
                    -jar ${BACKEND_DIR}/todo-api-${ARTIFACT_VERSION}.jar \
                    --spring.data.mongodb.username=${MONGO_USER} \
                    --spring.data.mongodb.password=${MONGO_PASSWORD} \
                    > ${BACKEND_DIR}/app.log 2>&1 &
                    if pgrep -f "todo-api-${ARTIFACT_VERSION}" > /dev/null; then
                        echo "Backend is running ✅"
                    else
                        echo "Backend failed to start ❌"
                        echo "Last 20 lines of app.log:"
                        tail -20 ${BACKEND_DIR}/app.log
                        exit 1
                    fi
                '''
            }
        }
        stage('Deploy Frontend') {
            steps {
                sh '''
                    echo "=== Setting up Node.js via NVM ==="
                    export NVM_DIR="/home/ubuntu1/.nvm"
                    source "$NVM_DIR/nvm.sh"

                    echo "Node version: $(node --version)"
                    echo "NPM version:  $(npm --version)"

                    echo "=== Stopping currently running frontend ==="
                    pkill -f "react-scripts" || true
                    sleep 3
                    echo "Old instance stopped"

                    echo "=== Setting environment variables ==="
                    cd ${FRONTEND_DIR}
                    bash env.sh

                    echo "=== Starting React frontend ==="
                    nohup npm start > ${FRONTEND_DIR}/ui.log 2>&1 &

                    echo "Waiting for frontend to start..."
                    sleep 10

                    echo "=== Checking if frontend started ==="
                    if pgrep -f "react-scripts" > /dev/null; then
                        echo "Frontend is running ✅"
                    else
                        echo "Frontend failed to start ❌"
                        echo "Last 20 lines of ui.log:"
                        tail -20 ${FRONTEND_DIR}/ui.log
                        exit 1
                    fi
                '''
            }
        }

    }
        post {
        success {
            echo """
            ╔══════════════════════════════════════════════╗
            ║   PIPELINE SUCCESS ✅                        ║
            ║   Version ${ARTIFACT_VERSION} deployed       ║
            ║                                              ║
            ║   Backend logs:                              ║
            ║   tail -f /home/ubuntu1/todo-api/app.log     ║
            ║                                              ║
            ║   Frontend logs:                             ║
            ║   tail -f /home/ubuntu1/todo-ui/ui.log       ║
            ╚══════════════════════════════════════════════╝
            """
        }
        failure {
            echo """
            ╔══════════════════════════════════════════════╗
            ║   PIPELINE FAILED ❌                         ║
            ║                                              ║
            ║   Check which stage is RED in Jenkins UI     ║
            ║   Click the stage → View Logs                ║
            ║                                              ║
            ║   Common fixes:                              ║
            ║   Build failed    → check Java/Maven version ║
            ║   Tests failed    → check app.log            ║
            ║   Quality Gate    → check SonarQube coverage ║
            ║   JFrog failed    → check token in AWS       ║
            ║   Deploy failed   → check MongoDB is running ║
            ╚══════════════════════════════════════════════╝
            """
        }
        aborted {
            echo "Pipeline was manually aborted at the Approval Gate. No deployment was made."
        }
    }

}