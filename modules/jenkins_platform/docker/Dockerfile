FROM --platform=linux/amd64 jenkins/jenkins:2.443
RUN jenkins-plugin-cli --version
USER root
RUN apt update && curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && ./aws/install && rm -rf awscliv2.zip ./aws && aws --version
USER jenkins
ENV CASC_JENKINS_CONFIG /usr/share/jenkins/ref/jenkins.yaml
COPY files/jenkins.yaml.tpl /usr/share/jenkins/ref/jenkins.yaml
RUN echo 2.0 > /usr/share/jenkins/ref/jenkins.install.UpgradeWizard.state
COPY files/InitialConfig.groovy /usr/share/jenkins/ref/init.groovy.d/InitialConfig.groovy
COPY --chown=jenkins:jenkins files/plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN jenkins-plugin-cli --verbose --plugin-file /usr/share/jenkins/ref/plugins.txt
