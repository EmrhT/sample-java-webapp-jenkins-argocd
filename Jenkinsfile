pipeline {
  agent {
    node {
      label 'kubeagent'
    }
  }
  
  environment {
    GITHUB_TOKEN = credentials('github-token')
  }
  
  stages {
    stage('Developer Pushed to Feature Branch of Application Repo') {
      steps {
        sh 'echo $GITHUB_TOKEN'
        sh 'true'
      }
    }
    stage('Jenkins Cloned the Feature Branch of Application Repo') {
      steps {
        sh 'git clone -b feature-emrah https://github.com/EmrhT/sample-java-webapp-jenkins-argocd.git'
      }
    }
    stage('Build') {
      steps {
        script {
            sh 'apk --no-cache add openjdk8'
            sh 'export JAVA_HOME=/usr/lib/jvm/java-8-openjdk; export PATH=$JAVA_HOME/bin:$PATH; ./gradlew build'
          }
        }
      }
     stage('Unit Test') {
      steps {
        script {
            sh 'export JAVA_HOME=/usr/lib/jvm/java-8-openjdk; export PATH=$JAVA_HOME/bin:$PATH; ./gradlew test'
          }
        }
      }
    stage('Sonar Scanner') {
      steps {
        script {
          def sonarqubeScannerHome = tool name: 'sonar', type: 'hudson.plugins.sonar.SonarRunnerInstallation'
          withCredentials([string(credentialsId: 'sonar', variable: 'sonarLogin')]) {
            sh "true || ${sonarqubeScannerHome}/bin/sonar-scanner -e -Dsonar.host.url=http://sonarqube-sonarqube.sonarqube.svc.cluster.local:9000 -Dsonar.login=${sonarLogin} -Dsonar.projectName=java-webapp -Dsonar.projectVersion=${env.BUILD_NUMBER} -Dsonar.projectKey=JW -Dsonar.sources=build/classes/main/ -Dsonar.tests=build/classes/test/ -Dsonar.language=java"
          }  
        }
      }
    }
    stage ('Podman Build & Push') {
      steps {
        sh "echo 192.168.122.15 harbor.example.com >> /etc/hosts"
        sh "podman build --network=host -t harbor.example.com/mantislogic/sample-java-webapp-jenkins:$GIT_COMMIT ."
        sh "podman login --tls-verify=false harbor.example.com -u admin -p $DOCKERHUB_PASS"
        sh "podman push --tls-verify=false harbor.example.com/mantislogic/sample-java-webapp-jenkins:$GIT_COMMIT"
      }
    }
    stage('Trivy Image Scan') {
      steps {
          sh 'curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin v0.18.3'
          sh 'curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/html.tpl > html.tpl'
          sh 'true || TRIVY_INSECURE=true trivy image --ignore-unfixed --vuln-type os,library --exit-code 1 --severity CRITICAL harbor.example.com/mantislogic/sample-java-webapp-jenkins:$GIT_COMMIT'
      }
    }

    stage('Clone Gitops Repo Feature Branch') {
      steps {
        sh 'git clone -b feature-emrah https://github.com/EmrhT/gitops-argocd-projects.git'
      }
    }
    
   stage('Update Manifest') {
      steps {
        dir("gitops-argocd-projects/sample-java-webapp-jenkins-argocd") {
          sh 'sed -i "s/{{GIT_COMMIT}}/$GIT_COMMIT/g" deployment.yaml'
        }
      }
    }
    
    stage('Commit & Push to Gitops Repo Feature Branch') {
      steps {
        dir("gitops-argocd-projects/sample-java-webapp-jenkins-argocd") {
          sh "git config --global user.email 'emrhtfn@gmail.com'"
          sh "git config --global user.name 'EmrhT'"
          sh 'echo $GITHUB_TOKEN'
          sh 'git remote set-url origin https://$GITHUB_TOKEN@github.com/EmrhT/gitops-argocd-projects.git'
          sh 'git checkout feature-emrah'
          sh 'git add -A'
          sh 'git commit -am "Updated image version for Build with commit ID - $GIT_COMMIT" || true'
          sh 'git push origin feature-emrah'
        }
      }
    }
    
    stage ('OWASP-ZAP Dynamic Scan') {
      steps {
          sh 'sleep 60'
          sh 'podman run --tls-verify=false -t harbor.example.com/mantislogic/zap2docker-stable:2.12.0 zap-baseline.py -t http://webapp-svc.sample-java-webapp-jenkins-test.svc.cluster.local:8080/Java_Webapp_Pipeline/rest/hello | tee owasp-results.txt || true'
          sh 'cat owasp-results.txt | egrep  "^FAIL-NEW: 0.*FAIL-INPROG: 0"'
      }
    }
    
    stage ('Merge Feature Branch to Master for Application Repo') {
      steps {
        sh 'true'
      }
    }
    
    stage ('Merge Feature Branch to Master for Gitops Repo') {
      steps {
        sh 'true'
      }
    }
    
    stage ('Delete Feature Branches for Both Repos ??? (auto???)') {
      steps {
        sh 'true'
      }
    }
  }
}
