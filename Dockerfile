FROM tomcat:9.0.73-jdk8

COPY build/libs/java_webapp_argocd.war /usr/local/tomcat/webapps/
EXPOSE 8080
