#########################Docker for redhat7#####################################################################

FROM  registry.redhat.io/rhel7
LABEL Shitalkumar dhawle <sdhawale@sae.org>
RUN subscription-manager register  --username sae-developer --password 'q4LT$A9z&4V$94@*JF^' --auto-attach  && \
    subscription-manager refresh
USER root
RUN yum install wget -y \
    yum install curl -y \
    yum install unzip -y 


##########################Installing OracleJDK and Preparing environment ########################################

ENV JAVA_HOME /opt/java
ENV PATH="/opt/java/bin:${PATH}"
ENV ADMIN_USER="jadmin"                                                                          
ENV ADMIN_PASSWORD="Admin!123"
ENV JBOSS_USER='jboss'

# Install Oracle Java8
ENV JAVA_VERSION 8u202
ENV JAVA_BUILD 8u202-b12

RUN wget https://s3.amazonaws.com/sae-dev-docker/software_installation/jdk-${JAVA_VERSION}-linux-x64.tar.gz && \
 tar -xvf jdk-${JAVA_VERSION}-linux-x64.tar.gz                                                              && \
 rm jdk*.tar.gz && \
 mv jdk* ${JAVA_HOME}

###################################### JBOSS-EAP-7.2 Installing ####################################################
# Create a user and group used to launch processes                                                                 #
# The user ID 1000 is the default for the first "regular" user on Fedora/RHEL,                                     #
# so there is a high chance that this ID will be equal to the current user                                         #
# making it easier to use volumes (no permission issues)                                                           #
####################################################################################################################
RUN mkdir -p /weblogic/jboss/jboss-eap-7.2

ENV JBOSS_BASE=/weblogic
ENV JBOSS_HOME=/weblogic/jboss

RUN groupadd -r jboss -g 2000 \
 && useradd -l -u 2000 -r -g jboss -m -d /weblogic/jboss/jboss-eap-7.2 -s /sbin/nologin -c "jboss user" jboss \
 && chmod -R 755 /weblogic/jboss/jboss-eap-7.2 \
 && mkdir ${JBOSS_BASE} > /dev/null 2&>1;  chmod 755 ${JBOSS_BASE} ; chown -R jboss:jboss ${JBOSS_BASE} \
 && echo 'jboss ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers 
USER ${JBOSS_USER}

WORKDIR ${JBOSS_HOME}

ADD jboss-eap-7.2.0.zip ${JBOSS_HOME} 
RUN cd /weblogic/jboss/ && ls 
RUN sh -c 'unzip -q jboss-eap-7.2.0.zip' && \
    ls && \
	whoami
#RUN mkdir -p /weblogic/debug/ && \
#    ls  
WORKDIR ${JBOSS_HOME}/jboss-eap-7.2 

RUN rm -rf /weblogic/jboss/jboss-eap-7.2.0.zip

RUN mkdir -p /weblogic/jboss/source/
RUN mkdir -p /weblogic/debug/jboss/dev3  
  
RUN mkdir -p /weblogic/weblogic/elasticapm 
RUN mkdir -p /weblogic/jboss/jboss-eap-7.2/modules/com && \
    mkdir -p /weblogic/jboss/jboss-eap-7.2/modules/saecommons/main && \
	mkdir -p /weblogic/jboss/deploy-staging/saeconfig  

USER ${JBOSS_USER}

COPY standalone.conf /weblogic/jboss/jboss-eap-7.2/bin/standalone.conf

RUN ls -l /weblogic/jboss/jboss-eap-7.2/bin/standalone.conf 
COPY  standalone.xml /weblogic/jboss/jboss-eap-7.2/standalone/configuration/standalone.xml

COPY  --chown=jboss source /weblogic/jboss/source/
COPY  --chown=jboss modules /weblogic/jboss/jboss-eap-7.2/modules/
COPY  --chown=jboss elasticapm /weblogic/weblogic/elasticapm/
COPY  --chown=jboss deploy-staging /weblogic/jboss/deploy-staging/
COPY  --chown=jboss deployments /weblogic/jboss/jboss-eap-7.2/standalone/deployments/

RUN  ls /weblogic/jboss/jboss-eap-7.2/bin
RUN mkdir /weblogic/jboss/jboss-eap-7.2/bin/saeconfig

RUN cd /weblogic/jboss/jboss-eap-7.2/bin/saeconfig 
COPY --chown=jboss saeconfig /weblogic/jboss/jboss-eap-7.2/bin/saeconfig/ 
RUN ls -al /weblogic/jboss/jboss-eap-7.2/bin/saeconfig
RUN cd /weblogic/jboss/jboss-eap-7.2/bin/saeconfig
RUN cd /weblogic/jboss/jboss-eap-7.2/standalone/deployments/ && \
       mv SAEEnterpriseApp.ear.dodeploy.txt /weblogic/jboss/jboss-eap-7.2/standalone/deployments/SAEEnterpriseApp.ear.dodeploy && ls
RUN cd ${JBOSS_HOME} && ls
USER ${JBOSS_USER}
ENV JBOSS_HOME=/weblogic/jboss/jboss-eap-7.2
########## Expose the ports we're interested in, 8080, for webinterface and 9990 for Admin Console ###################
EXPOSE 9990 8080 8009
######################### This will boot JBoss in the standalone mode and bind to all interface ######################
RUN /weblogic/jboss/jboss-eap-7.2/bin/add-user.sh ${ADMIN_USER} ${ADMIN_PASSWORD} --silent 
#COPY --chown=jboss startjboss.sh /weblogic/jboss/
#RUN chmod +x /weblogic/jboss/startjboss.sh 

#CMD ["/weblogic/jboss/jboss-eap-7.2/bin/", standalone.sh", "-b", "0.0.0.0", "-bmanagement", "0.0.0.0"]  
#RUN cd /weblogic/jboss/jboss-eap-7.2/bin/ && \
#     standalone.sh -b 0.0.0.0 

#CMD ["/startjboss.sh"]

CMD ["sh","-c","cd /weblogic/jboss/jboss-eap-7.2/bin/ && ./standalone.sh -b 0.0.0.0 "]
#############################################END ############################################################################





